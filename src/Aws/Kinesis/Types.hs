-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Types
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
-- Module: Aws.Kinesis.Types
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- The Amazon Kinesis Service API Reference API contains several data types
-- that various actions use.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_Types.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}

module Aws.Kinesis.Types
( StreamName
, streamName
, streamNameText

, ShardId
, SequenceNumber

, PartitionHash
, partitionHash
, partitionHashInteger

, PartitionKey
, partitionKey
, partitionKeyText

, ShardIterator
, ShardIteratorType(..)
, Record(..)
, StreamDescription(..)
, StreamStatus(..)
, Shard(..)
) where

#ifndef MIN_VERSION_base
#define MIN_VERSION_base(x,y,z) 1
#endif

import Aws.General

#if ! MIN_VERSION_base(4,8,0)
import Control.Applicative
#endif
import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString as B
import qualified Data.ByteString.Base64 as B64
import Data.Monoid
import Data.String
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.Read as T
import Data.Typeable

import GHC.Generics

import Test.QuickCheck
import Test.QuickCheck.Instances ()

-- -------------------------------------------------------------------------- --
-- Internal Utils

sshow :: (Show a, IsString b) => a -> b
sshow = fromString . show

tryM :: Monad m => Either T.Text a -> m a
tryM = either (fail . T.unpack) return

-- -------------------------------------------------------------------------- --
-- | Stream Name
--
-- The stream name is scoped to the AWS account used by the application that
-- creates the stream. It is also scoped by region. That is, two streams in two
-- different AWS accounts can have the same name, and two streams in the same
-- AWS account, but in two different regions, can have the same name.
--
-- Length constraints: Minimum length of 1. Maximum length of 128.
--
-- Error responses from AWS Kinesis indicate that stream names must
-- match the following regular expressions:
--
-- > [a-zA-Z0-9_.-]+
--
newtype StreamName = StreamName { streamNameText :: T.Text }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData StreamName

-- | Smart Constructor for 'StreamName' that enforces size constraints.
--
-- For static construction you may also use the 'IsString' instance
-- that throws an 'error' on invalid stream names.
--
streamName :: T.Text -> Either T.Text StreamName
streamName t
    | T.length t < 1 = Left $ "Illegal StreamName " <> sshow t <> "; StreamName must be of length at least 1"
    | T.length t > 128 = Left $ "Illegal StreamName " <> sshow t <> "; StreamName must be of length at most 128"
    | otherwise = Right $ StreamName t

-- | The 'fromString' function of this instance raises and asynchronous 'error'
-- if the argument 'String' is not a legal 'StreamName'.
--
instance IsString StreamName where
    fromString = either (error . T.unpack) id . streamName . T.pack

instance ToJSON StreamName where
    toJSON = toJSON . streamNameText

instance FromJSON StreamName where
    parseJSON = withText "StreamName" $ tryM . streamName

instance Arbitrary StreamName where
    arbitrary = StreamName . T.pack <$> (resize 128 . listOf1 $ elements chars)
      where
        chars = ['a' .. 'z'] <> ['A' .. 'Z'] <> ['0' .. '9'] <> "_.-"

-- -------------------------------------------------------------------------- --
-- | Identifier for a shard as returned by PutRecord.
--
-- Length constraints: Minimum length of 1. Maximum length of 128.
--
newtype ShardId = ShardId { shardIdText :: T.Text }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData ShardId

instance ToJSON ShardId where
    toJSON = toJSON . shardIdText

instance FromJSON ShardId where
    parseJSON = withText "ShardId" $ return . ShardId

instance Arbitrary ShardId where
    arbitrary = ShardId <$> (resize 128 arbitrary `suchThat` (not . T.null))

-- -------------------------------------------------------------------------- --
-- | Opaque sequence number as returned by PutRecord.
--
newtype SequenceNumber = SequenceNumber { sequenceNumberText :: T.Text }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData SequenceNumber

instance ToJSON SequenceNumber where
    toJSON = toJSON . sequenceNumberText

instance FromJSON SequenceNumber where
    parseJSON = withText "SequenceNumber" $ return . SequenceNumber

instance Arbitrary SequenceNumber where
    arbitrary = SequenceNumber . T.pack . show . getPositive
        <$> (arbitrary :: Gen (Positive Integer))

-- -------------------------------------------------------------------------- --
-- | An 128 bit interger that identifies the partition. The default
-- is the MD5 hash of the partition key.
--
-- FIXME the specification is rather vague about the precise encoding
-- of this value. The default is to compute it as an MD5 hash of
-- the partition key. The API reference describes it as an Int128.
-- However, it is not clear how the result of the hash function is
-- encoded (big-endian or small endian, word size?) and how it is
-- serialized to text, which is the type in the JSON serialization.
--
-- <http://javadox.com/com.amazonaws/aws-java-sdk/1.7.1/com/amazonaws/services/kinesis/model/PutRecordRequest.html>
-- seems to indicate that the value is actually unsigned.
--
newtype PartitionHash = PartitionHash { partitionHashInteger :: Integer {- FIXME -} }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData PartitionHash

-- | Smart Constructor for 'PartitionHash' that enforces size constraints.
--
partitionHash :: Integer -> Either T.Text PartitionHash
partitionHash i
    | i >= 2^(128 :: Int) = Left $ "partition hash " <> sshow i <> "is out of range; a partition hash must be a 128 bit unsigned integer"
    | i < 0 = Left $ "partition hash " <> sshow i <> "is out of range; a partition hash must be a 128 bit unsigned integer"
    | otherwise = Right $ PartitionHash i

instance ToJSON PartitionHash where
    toJSON = toJSON . show . partitionHashInteger

instance FromJSON PartitionHash where
    parseJSON = withText "PartitionHash" $ \t -> case T.decimal t of
        Right (a, "") -> tryM $ partitionHash a
        Right (_, x) -> fail $ "trailing text: " <> T.unpack x
        Left e -> fail e

instance Arbitrary PartitionHash where
    arbitrary = PartitionHash . getPositive <$> resize (2^(128 :: Int) - 1) arbitrary

-- -------------------------------------------------------------------------- --
-- | PartitionKey
--
-- Identifies which shard in the stream the data record is assigned to.
--
-- Partition keys are Unicode strings with a maximum length limit of 256
-- bytes. Amazon Kinesis uses the partition key as input to a hash function
-- that maps the partition key and associated data to a specific shard.
-- Specifically, an MD5 hash function is used to map partition keys to
-- 128-bit integer values and to map associated data records to shards. As
-- a result of this hashing mechanism, all data records with the same
-- partition key will map to the same shard within the stream.
--
-- Length constraints: Minimum length of 1. Maximum length of 256.
--
newtype PartitionKey = PartitionKey { partitionKeyText :: T.Text }
    deriving (Show, Read, Eq, Ord, IsString, Typeable, Generic)

instance NFData PartitionKey

partitionKey :: T.Text -> Either T.Text PartitionKey
partitionKey t
    | T.length t < 1 = Left $ "Illegal PartitionKey " <> sshow t <> "; PartitionKey must be of length at least 1"
    | T.length t > 256 = Left $ "Illegal PartitionKey " <> sshow t <> "; PartitionKey must be of length at most 256"
    | otherwise = Right $ PartitionKey t

instance ToJSON PartitionKey where
    toJSON = toJSON . partitionKeyText

instance FromJSON PartitionKey where
    parseJSON = withText "PartitionKey" $ tryM . partitionKey

instance Arbitrary PartitionKey where
    arbitrary = PartitionKey
        <$> (resize 256 arbitrary `suchThat` (not . T.null))

-- -------------------------------------------------------------------------- --
-- | Iterator for records within a shard.
--
-- Length constraints: Minimum length of 1. Maximum length of 512.
--
newtype ShardIterator = ShardIterator { shardIteratorText :: T.Text }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData ShardIterator

shardIterator :: T.Text -> Either T.Text ShardIterator
shardIterator t
    | T.length t < 1 = Left $ "Illegal ShardIterator " <> sshow t <> "; ShardIterator must be of length at least 1"
    | T.length t > 512 = Left $ "Illegal ShardIterator " <> sshow t <> "; ShardIterator must be of length at most 512"
    | otherwise = Right $ ShardIterator t

instance ToJSON ShardIterator where
    toJSON = toJSON . shardIteratorText

instance FromJSON ShardIterator where
    parseJSON = withText "ShardIterator" $ tryM . shardIterator

instance Arbitrary ShardIterator where
    arbitrary = ShardIterator
        <$> (resize 512 arbitrary `suchThat` (not . T.null))

-- -------------------------------------------------------------------------- --
-- | ShardIteratorType
--
-- Determines how the shard iterator is used to start reading data records from
-- the shard.
--
data ShardIteratorType
    = AtSequenceNumber
    -- ^ Start reading exactly from the position denoted by a specific sequence
    -- number.

    | AfterSequenceNumber
    -- ^ Start reading right after the position denoted by a specific sequence
    -- number.

    | TrimHorizon
    -- ^ Start reading at the last untrimmed record in the shard in the system,
    -- which is the oldest data record in the shard.

    | Latest
    -- ^ Start reading just after the most recent record in the shard, so that
    -- you always read the most recent data in the shard.

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData ShardIteratorType

instance ToJSON ShardIteratorType where
    toJSON AtSequenceNumber = "AT_SEQUENCE_NUMBER"
    toJSON AfterSequenceNumber = "AFTER_SEQUENCE_NUMBER"
    toJSON TrimHorizon = "TRIM_HORIZON"
    toJSON Latest = "LATEST"

instance FromJSON ShardIteratorType where
    parseJSON = withText "SharedIteratorType" $ \t -> case t of
        "AT_SEQUENCE_NUMBER" -> return AtSequenceNumber
        "AFTER_SEQUENCE_NUMBER" -> return AfterSequenceNumber
        "TRIM_HORIZON" -> return TrimHorizon
        "LATEST" -> return Latest
        e -> fail $ "unexpected value for SharedIteratorType: " <> T.unpack e

instance Arbitrary ShardIteratorType where
    arbitrary = elements [minBound .. maxBound]

-- -------------------------------------------------------------------------- --
-- | Record
--
-- The unit of data of the Amazon Kinesis stream, which is composed of a
-- sequence number, a partition key, and a data blob.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_Record.html>
--
data Record = Record
    { recordData :: !B.ByteString
    -- ^ The data blob. The data in the blob is both opaque and immutable to
    -- the Amazon Kinesis service, which does not inspect, interpret, or change
    -- the data in the blob in any way. The maximum size of the data blob (the
    -- payload after Base64-decoding) is 50 kilobytes (KB)
    --
    -- Length constraints: Minimum length of 0. Maximum length of 51200.
    --
    -- Note that the size constraint is not currently enforced in the code.

    , recordPartitionKey :: !PartitionKey
    -- ^ Identifies which shard in the stream the data record is assigned to.

    , recordSequenceNumber :: !SequenceNumber
    -- ^ The unique identifier for the record in the Amazon Kinesis stream.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData Record

instance ToJSON Record where
    toJSON Record{..} = object
        [ "Data" .= T.decodeUtf8 (B64.encode recordData)
        , "PartitionKey" .= recordPartitionKey
        , "SequenceNumber" .= recordSequenceNumber
        ]

instance FromJSON Record where
    parseJSON = withObject "Record" $ \o -> Record
        <$> (from64 =<< o .: "Data")
        <*> o .: "PartitionKey"
        <*> o .: "SequenceNumber"
      where
        from64 x = case B64.decode (T.encodeUtf8 x) of
            Left e -> fail $ "failed to decode base64 encoded data: " <> e
            Right a -> return a

instance Arbitrary Record where
    arbitrary = Record
        <$> (arbitrary `suchThat` ((<= 51200) . B.length))
        <*> arbitrary
        <*> arbitrary

-- -------------------------------------------------------------------------- --
-- Stream Description
--
-- Represents the output of a DescribeStream operation.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_StreamDescription.html>
--
data StreamDescription = StreamDescription
    { streamDescriptionHasMoreShards :: !Bool
    -- ^ If set to true there are more shards in the stream available to
    -- describe.

    , streamDescriptionShards :: ![Shard]
    -- ^ The shards that comprise the stream.

    , streamDescriptionStreamARN :: !Arn
    -- ^The Amazon Resource Name (ARN) for the stream being described.

    , streamDescriptionStreamName :: !StreamName
    -- ^ The name of the stream being described.

    , streamDescriptionStreamStatus :: !StreamStatus
    -- ^ The current status of the stream being described.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData StreamDescription

instance ToJSON StreamDescription where
    toJSON StreamDescription{..} = object
        [ "HasMoreShards" .= streamDescriptionHasMoreShards
        , "Shards" .= streamDescriptionShards
        , "StreamARN" .= streamDescriptionStreamARN
        , "StreamName" .= streamDescriptionStreamName
        , "StreamStatus" .= streamDescriptionStreamStatus
        ]

instance FromJSON StreamDescription where
    parseJSON = withObject "StreamDescription" $ \o -> StreamDescription
        <$> o .: "HasMoreShards"
        <*> o .: "Shards"
        <*> o .: "StreamARN"
        <*> o .: "StreamName"
        <*> o .: "StreamStatus"

instance Arbitrary StreamDescription where
    arbitrary = StreamDescription
        <$> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary

-- | Stream Status
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_StreamDescription.html>
--
data StreamStatus
    = StreamStatusCreating
    -- ^ The stream is being created. Upon receiving a CreateStream request,
    -- Amazon Kinesis immediately returns and sets StreamStatus to CREATING.

    | StreamStatusDeleting
    -- ^ The stream is being deleted. After a DeleteStream request, the
    -- specified stream is in the DELETING state until Amazon Kinesis completes
    -- the deletion.

    | StreamStatusActive
    -- ^ The stream exists and is ready for read and write operations or
    -- deletion. You should perform read and write operations only on an ACTIVE
    -- stream.

    | StreamStatusUpdating
    -- ^ Shards in the stream are being merged or split. Read and write
    -- operations continue to work while the stream is in the UPDATING state.

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData StreamStatus

instance ToJSON StreamStatus where
    toJSON StreamStatusCreating = "CREATING"
    toJSON StreamStatusDeleting = "DELETING"
    toJSON StreamStatusActive = "ACTIVE"
    toJSON StreamStatusUpdating = "UPDATING"

instance FromJSON StreamStatus where
    parseJSON = withText "StreamStatus" $ \t -> case t of
        "CREATING" -> return StreamStatusCreating
        "DELETING" -> return StreamStatusDeleting
        "ACTIVE" -> return StreamStatusActive
        "UPDATING" -> return StreamStatusUpdating
        e -> fail $ "unexpected value for StreamStatus: " <> T.unpack e

instance Arbitrary StreamStatus where
    arbitrary = elements [minBound .. maxBound]

-- | Shard
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_Shard.html>
--
data Shard = Shard
    { shardAdjacentParentShardId :: !(Maybe ShardId)
    -- ^ The shard Id of the shard adjacent to the shard's parent.

    , shardHashKeyRange :: !(PartitionHash, PartitionHash)
    -- ^ The (inclusive) range of possible hash key values for the shard, which is a set of
    -- ordered contiguous positive integers.
    --
    -- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_HashKeyRange.html>

    , shardParentShardId :: !(Maybe ShardId)
    -- ^ The shard Id of the shard's parent.

    , shardSequenceNumberRange :: !(SequenceNumber, Maybe SequenceNumber)
    -- ^ The (inclusive) range of possible sequence numbers for the shard.
    --
    -- Shards that are in the OPEN state have an ending sequence number of 'Nothing'.
    --
    -- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_SequenceNumberRange.html>

    , shardShardId :: ShardId
    -- ^ The unique identifier of the shard within the Amazon Kinesis stream.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData Shard

instance ToJSON Shard where
    toJSON Shard{..} = object
        [ "AdjacentParentShardId" .= shardAdjacentParentShardId
        , "HashKeyRange" .= object
            [ "StartingHashKey" .= fst shardHashKeyRange
            , "EndingHashKey" .= snd shardHashKeyRange
            ]
        , "ParentShardId" .= shardParentShardId
        , "SequenceNumberRange" .= object
            [ "StartingSequenceNumber" .= fst shardSequenceNumberRange
            , "EndingSequenceNumber" .= snd shardSequenceNumberRange
            ]
        , "ShardId" .= shardShardId
        ]

instance FromJSON Shard where
    parseJSON = withObject "Shard" $ \o -> Shard
        <$> o .:? "AdjacentParentShardId" .!= Nothing
        <*> (hashKeyRange =<< o .: "HashKeyRange")
        <*> o .:? "ParentShardId" .!= Nothing
        <*> (sequenceNumberRange =<< o .: "SequenceNumberRange")
        <*> o .: "ShardId"
      where
        hashKeyRange = withObject "HashKeyRange" $ \o -> (,)
            <$> o .: "StartingHashKey"
            <*> o .: "EndingHashKey"
        sequenceNumberRange = withObject "SequenceNumberRange" $ \o -> (,)
            <$> o .: "StartingSequenceNumber"
            <*> o .:? "EndingSequenceNumber" .!= Nothing

instance Arbitrary Shard where
    arbitrary = Shard
        <$> arbitrary
        <*> do
            u <- arbitrary
            l <- resize (fromIntegral $ partitionHashInteger u) arbitrary
            return (l,u)
        <*> arbitrary
        <*> do
            u <- arbitrary
            l <- resize (maybe maxBound (read . T.unpack . sequenceNumberText) u) arbitrary
            return (l,u)
        <*> arbitrary
