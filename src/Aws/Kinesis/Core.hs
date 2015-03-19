-- Copyright (c) 2013-2014 PivotCloud, Inc.
--
-- Aws.Kinesis.Core
--
-- Please feel free to contact us at licensing@pivotmail.com with any
-- contributions, additions, or other feedback; we would love to hear from
-- you.
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may
-- not use this file except in compliance with the License. You may obtain a
-- copy of the License at http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
-- WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
-- License for the specific language governing permissions and limitations
-- under the License.

-- |
-- Module: Aws.Kinesis.Core
-- Copyright: Copyright (c) 2013-2014 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference>

{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}

module Aws.Kinesis.Core
(
  KinesisVersion(..)

-- * Kinesis Client Configuration
, KinesisConfiguration(..)

-- * Kinesis Client Metadata
, KinesisMetadata(..)

-- * Kinesis Exceptions
, KinesisErrorResponse(..)

-- * Internal

-- ** Kinesis Actions
, KinesisAction(..)
, kinesisActionToText
, parseKinesisAction

-- ** Kinesis AWS Service Endpoints
, kinesisServiceEndpoint

-- ** Kinesis Queries
, KinesisQuery(..)
, kinesisSignQuery

-- ** Kinesis Responses
, kinesisResponseConsumer
, jsonResponseConsumer

-- ** Kinesis Errors and Common Parameters
, KinesisError(..)
, KinesisCommonParameters(..)
, KinesisCommonError(..)
) where

import Aws.Core
import Aws.General
import Aws.SignatureV4

import qualified Blaze.ByteString.Builder as BB

import Control.Applicative
import Control.Exception
import Control.Monad.IO.Class
import Control.Monad.Trans.Resource (throwM)

import Data.Aeson
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as LB
import qualified Data.ByteString.Char8 as B8
import Data.Conduit (($$+-))
import Data.Conduit.Binary (sinkLbs)
import Data.IORef
import Data.Maybe
import Data.Monoid
import Data.String
import Data.Time.Clock
import Data.Typeable
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import qualified Network.HTTP.Types as HTTP
import qualified Network.HTTP.Conduit as HTTP

import qualified Test.QuickCheck as Q

import qualified Text.Parser.Char as P
import Text.Parser.Combinators ((<?>))

data KinesisVersion
    = KinesisVersion_2013_12_02

kinesisTargetVersion :: IsString a => a
kinesisTargetVersion = "Kinesis_20131202"

-- -------------------------------------------------------------------------- --
-- Kinesis Actions

data KinesisAction
    = KinesisCreateStream
    | KinesisDeleteStream
    | KinesisDescribeStream
    | KinesisGetRecords
    | KinesisGetShardIterator
    | KinesisListStreams
    | KinesisMergeShards
    | KinesisPutRecord
    | KinesisPutRecords
    | KinesisSplitShard
    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable)

kinesisActionToText :: IsString a => KinesisAction -> a
kinesisActionToText KinesisCreateStream = "CreateStream"
kinesisActionToText KinesisDeleteStream = "DeleteStream"
kinesisActionToText KinesisDescribeStream = "DescribeStream"
kinesisActionToText KinesisGetRecords = "GetRecords"
kinesisActionToText KinesisGetShardIterator = "GetShardIterator"
kinesisActionToText KinesisListStreams = "ListStreams"
kinesisActionToText KinesisMergeShards = "MergeShards"
kinesisActionToText KinesisPutRecord = "PutRecord"
kinesisActionToText KinesisPutRecords = "PutRecords"
kinesisActionToText KinesisSplitShard = "SplitShard"

parseKinesisAction :: P.CharParsing m => m KinesisAction
parseKinesisAction =
        KinesisCreateStream <$ P.text "CreateStream"
    <|> KinesisDeleteStream <$ P.text "DeleteStream"
    <|> KinesisDescribeStream <$ P.text "DescribeStream"
    <|> KinesisGetRecords <$ P.text "GetRecords"
    <|> KinesisGetShardIterator <$ P.text "GetShardIterator"
    <|> KinesisListStreams <$ P.text "ListStreams"
    <|> KinesisMergeShards <$ P.text "MergeShards"
    <|> KinesisPutRecord <$ P.text "PutRecord"
    <|> KinesisPutRecords <$ P.text "PutRecords"
    <|> KinesisSplitShard <$ P.text "SplitShard"
    <?> "KinesisAction"

instance AwsType KinesisAction where
    toText = kinesisActionToText
    parse = parseKinesisAction

instance Q.Arbitrary KinesisAction where
    arbitrary = Q.elements [minBound..maxBound]

kinesisTargetHeader :: KinesisAction -> HTTP.Header
kinesisTargetHeader a = ("X-Amz-Target", kinesisTargetVersion <> "." <> toText a)

-- -------------------------------------------------------------------------- --
-- Kinesis AWS Service Endpoints

-- | Kinesis Endpoints as specified in AWS General API version 0.1
--
-- <http://docs.aws.amazon.com/general/1.0/gr/rande.html#ak_region>
--
kinesisServiceEndpoint :: Region -> B8.ByteString
kinesisServiceEndpoint ApNortheast1 = "kinesis.ap-northeast-1.amazonaws.com"
kinesisServiceEndpoint ApSoutheast1 = "kinesis.ap-southeast-1.amazonaws.com"
kinesisServiceEndpoint ApSoutheast2 = "kinesis.ap-southeast-2.amazonaws.com"
kinesisServiceEndpoint EuWest1 = "kinesis.eu-west-1.amazonaws.com"
kinesisServiceEndpoint UsEast1 = "kinesis.us-east-1.amazonaws.com"
kinesisServiceEndpoint UsWest2 = "kinesis.us-west-2.amazonaws.com"
kinesisServiceEndpoint (CustomEndpoint e _) = T.encodeUtf8 e
kinesisServiceEndpoint r = error $ "Aws.Kinesis.Core.kinesisServiceEndpoint: unsupported region " <> show r -- FIXME

-- -------------------------------------------------------------------------- --
-- Kinesis Metadata

data KinesisMetadata = KinesisMetadata
    { kinesisMAmzId2 :: Maybe T.Text
    , kinesisMRequestId :: Maybe T.Text
    }
    deriving (Show)

instance Loggable KinesisMetadata where
    toLogText (KinesisMetadata rid id2) =
        "Kinesis: request ID=" <> fromMaybe "<none>" rid
        <> ", x-amz-id-2=" <> fromMaybe "<none>" id2

instance Monoid KinesisMetadata where
    mempty = KinesisMetadata Nothing Nothing
    KinesisMetadata id1 r1 `mappend` KinesisMetadata id2 r2 = KinesisMetadata (id1 <|> id2) (r1 <|> r2)

-- -------------------------------------------------------------------------- --
-- Kinesis Configuration

data KinesisConfiguration qt = KinesisConfiguration
    { kinesisConfRegion :: Region
    }
    deriving (Show)

-- -------------------------------------------------------------------------- --
-- Kinesis Query

data KinesisQuery = KinesisQuery
    { kinesisQueryAction :: !KinesisAction
    , kinesisQueryBody :: !(Maybe B.ByteString)
    }
    deriving (Show, Eq)

-- | Creates a signed query.
--
-- Uses AWS Signature V4. All requests are POST requests
-- with the signature placed in an HTTP header
--
kinesisSignQuery :: KinesisQuery -> KinesisConfiguration qt -> SignatureData -> SignedQuery
kinesisSignQuery query conf sigData = SignedQuery
    { sqMethod = Post
    , sqProtocol = HTTPS
    , sqHost = host
    , sqPort = port
    , sqPath = BB.toByteString $ HTTP.encodePathSegments path
    , sqQuery = reqQuery
    , sqDate = Nothing
    , sqAuthorization = authorization
    , sqContentType = contentType
    , sqContentMd5 = Nothing
    , sqAmzHeaders = amzHeaders
    , sqOtherHeaders = [] -- we put everything into amzHeaders
    , sqBody = HTTP.RequestBodyBS <$> body
    , sqStringToSign = mempty -- Let me know if you really need this...
    }
  where
    path = []
    reqQuery = []
    host = kinesisServiceEndpoint $ kinesisConfRegion conf
    headers = [("host", host), kinesisTargetHeader (kinesisQueryAction query)]
    port = case kinesisConfRegion conf of
               CustomEndpoint _ p -> p
               _ -> 443
    contentType = Just "application/x-amz-json-1.1"
    body = kinesisQueryBody query

    amzHeaders = filter ((/= "Authorization") . fst) sig
    authorization = return <$> lookup "authorization" sig
    sig = either error id $ signPostRequest
            (cred2cred $ signatureCredentials sigData)
            (kinesisConfRegion conf)
            ServiceNamespaceKinesis
            (signatureTime sigData)
            "POST"
            path
            reqQuery
            headers
            (fromMaybe "" body)

#if MIN_VERSION_aws(0,9,2)
    cred2cred (Credentials a b c d) = SignatureV4Credentials a b c d
#else
    cred2cred (Credentials a b c) = SignatureV4Credentials a b c Nothing
#endif

-- -------------------------------------------------------------------------- --
-- Kinesis Response Consumer

-- | Create a complete 'HTTPResponseConsumer' for response types with an FromJSON instance
--
jsonResponseConsumer
    :: FromJSON a
    => HTTPResponseConsumer a
jsonResponseConsumer res = do
    doc <- HTTP.responseBody res $$+- sinkLbs
    case eitherDecode (if doc == mempty then "{}" else doc) of
        Left err -> throwM . KinesisResponseJsonError $ T.pack err
        Right v -> return v

kinesisResponseConsumer
    :: FromJSON a
    => IORef KinesisMetadata
    -> HTTPResponseConsumer a
kinesisResponseConsumer metadata resp = do

    let headerString = fmap T.decodeUtf8 . flip lookup (HTTP.responseHeaders resp)
        amzId2 = headerString "x-amz-id-2"
        requestId = headerString "x-amz-request-id"
        m = KinesisMetadata
            { kinesisMAmzId2 = amzId2
            , kinesisMRequestId = requestId
            }

    liftIO $ tellMetadataRef metadata m

    if HTTP.responseStatus resp >= HTTP.status400
        then errorResponseConsumer resp
        else jsonResponseConsumer resp

-- | Parse Error Responses
--
errorResponseConsumer :: HTTPResponseConsumer a
errorResponseConsumer resp = do
    doc <- HTTP.responseBody resp $$+- sinkLbs
    if HTTP.responseStatus resp == HTTP.status400
        then kinesisError doc
        else throwM KinesisOtherError
            { kinesisOtherErrorStatus = HTTP.responseStatus resp
            , kinesisOtherErrorMessage = T.decodeUtf8 $ LB.toStrict doc
            }
  where
    kinesisError doc = case eitherDecode doc of
        Left e -> throwM . KinesisResponseJsonError $ T.pack e
        Right a -> throwM (a :: KinesisErrorResponse)

-- -------------------------------------------------------------------------- --
-- Kinesis Errors

-- | TODO integrate typed errors
--
data KinesisError a
    = KinesisErrorCommon KinesisCommonError
    | KinesisErrorCommand a
    deriving (Show, Read, Eq, Ord, Typeable)

-- | All Kinesis exceptions have HTTP status code 400 and include
-- a JSON body with an exception type property and a short message.
--
data KinesisErrorResponse
    = KinesisErrorResponse
        { kinesisErrorCode :: !T.Text
        , kinesisErrorMessage :: !T.Text
        }
    | KinesisResponseJsonError T.Text
    | KinesisOtherError
        { kinesisOtherErrorStatus :: !HTTP.Status
        , kinesisOtherErrorMessage :: !T.Text
        }
    deriving (Show, Eq, Ord, Typeable)

instance Exception KinesisErrorResponse

-- | This instance captures only the 'KinesisErrorResponse' constructor
--
instance FromJSON KinesisErrorResponse where
    parseJSON = withObject "KinesisErrorResponse" $ \o -> KinesisErrorResponse
        <$> o .: "__type"
        <*> (o .: "message" <|> o .: "Message" <|> pure "")

-- | Common Kinesis Errors
--
-- <http://docs.aws.amazon.com/sns/2010-03-31/APIReference/CommonErrors.html>
--
-- TODO add function to provide info about the error (content of haddock comments)
--
data KinesisCommonError

    -- | The request signature does not conform to AWS standards.
    --
    -- /Code 400/
    --
    = ErrorIncompleteSignature

    -- | The request processing has failed because of an unknown error,
    -- exception or failure.
    --
    -- /Code 500/
    --
    | ErrorInternalFailure

    -- | The action or operation requested is invalid. Verify that the action
    -- is typed correctly.
    --
    -- /Code 400/
    --
    | ErrorInvalidAction

    -- | The X.509 certificate or AWS access key ID provided does not exist in
    -- our records.
    --
    -- /Code 403/
    --
    | ErrorInvalidClientTokenId

    -- | Parameters that must not be used together were used together.
    --
    -- /Code 400/
    --
    | ErrorInvalidParameterCombination

    -- | An invalid or out-of-range value was supplied for the input parameter.
    --
    -- /Code 400/
    --
    | ErrorInvalidParameterValue

    -- | The AWS query string is malformed or does not adhere to AWS standards.
    --
    -- /Code 400/
    --
    | ErrorInvalidQueryParamter

    -- | The query string contains a syntax error.
    --
    -- /Code 404/
    --
    | ErrorMalformedQueryString

    -- | The request is missing an action or a required parameter.
    --
    -- /Code 400/
    --
    | ErrorMissingAction

    -- | The request must contain either a valid (registered) AWS access key ID
    -- or X.509 certificate.
    --
    -- /Code 403/
    --
    | ErrorMissingAuthenticationToken

    -- | A required parameter for the specified action is not supplied.
    --
    -- /Code 400/
    --
    | ErrorMissingParameter

    -- | The AWS access key ID needs a subscription for the service.
    --
    -- /Code 403/
    --
    | ErrorOptInRequired

    -- | The request reached the service more than 15 minutes after the date
    -- stamp on the request or more than 15 minutes after the request
    -- expiration date (such as for pre-signed URLs), or the date stamp on the
    -- request is more than 15 minutes in the future.
    --
    -- /Code 400/
    --
    | ErrorRequestExpired

    -- | The request has failed due to a temporary failure of the server.
    --
    -- /Code 503/
    --
    | ErrorServiceUnavailable

    -- | The request was denied due to request throttling.
    --
    -- /Code 400/
    --
    | ErrorThrottling

    -- | The input fails to satisfy the constraints specified by an AWS
    -- service.
    --
    -- /Code 400/
    --
    | ErrorValidationError
    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable)

-- -------------------------------------------------------------------------- --
-- Common Parameters

-- | Common Kinesis Parameters
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/CommonParameters.html>
--
-- The user of this API hardy needs to deal with the data type directly.
--
-- This API supports only signature version 4 with signature method @AWS4-HMAC-SHA256@.
--
-- /This is not currently used for computing the requests, but serves as
-- documentation and reference for the implementation of yet missing features./
--
data KinesisCommonParameters = KinesisCommonParameters
    { kinesisAction :: !KinesisAction
    -- ^ The action to be performed.

    , kinesisAuthParams :: !(Maybe ()) --
    -- ^ The parameters that are required to authenticate a Conditional request. Contains:
    --
    -- * AWSAccessKeyID
    --
    -- * SignatureVersion
    --
    -- * Timestamp
    --
    -- * Signature

    , kinesisAWSAccessKeyId :: !B8.ByteString
    -- ^ The access key ID that corresponds to the secret access key that you used to sign the request.

    , kinesisExpires :: !UTCTime
    -- ^ The date and time when the request signature expires.
    -- Precisely one of snsExpires or snsTimestamp must be present.
    --
    -- format: @YYYY-MM-DDThh:mm:ssZ@ (ISO 8601)

    , kinesisTimestamp :: !UTCTime
    -- ^ The date and time of the request.
    -- Precisely one of snsExpires or snsTimestamp must be present.
    --
    -- format: @YYYY-MM-DDThh:mm:ssZ@ (ISO 8601)

    , kinesisSecurityToken :: () -- !(Maybe SecurityToken)
    -- ^ TODO
    --
    -- The temporary security token that was obtained through a call to AWS
    -- Security Token Service. For a list of services that support AWS Security
    -- Token Service, go to Using Temporary Security Credentials to Access AWS
    -- in Using Temporary Security Credentials.

    , kinesisSignature :: !Signature
    -- ^ The digital signature that you created for the request. For
    -- information about generating a signature, go to the service's developer
    -- documentation.

    , kinesisSignatureMethod :: !SignatureMethod
    -- ^ The hash algorithm that you used to create the request signature.
    --
    -- Valid Values: @HmacSHA256@ | @HmacSHA1@

    , kinesisSignatureVersion :: !SignatureVersion
    -- ^ The signature version you use to sign the request. Set this to the value that is recommended for your service.

    , kinesisVersion :: KinesisVersion
    -- ^ The API version that the request is written for.
    }

