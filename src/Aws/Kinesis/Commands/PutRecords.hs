{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}

-- |
-- Module: Kinesis.Commands.PutRecord
-- Copyright: Copyright © 2014 AlephCloud Systems, Inc.
-- License: MIT
-- Maintainer: Jon Sterling <jsterling@alephcloud.com>
-- Stability: experimental
--
-- TODO: Document this module, but only after the API is public so we aren't
-- chasing documentation changes.
--
module Aws.Kinesis.Commands.PutRecords
( PutRecords(..)
, PutRecordsItem(..)
, PutRecordsResponse(..)
, PutRecordsResponseRecord(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types
import Control.Applicative
import Data.Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Base64 as B64
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

data PutRecordsItem
    = PutRecordsItem
    { putRecordsItemData :: !BS.ByteString
    , putRecordsItemExplicitHashKey :: !(Maybe PartitionHash)
    , putRecordsItemPartitionKey :: !PartitionKey
    } deriving Show

data PutRecords
    = PutRecords
    { putRecordsRecords :: ![PutRecordsItem]
    , putRecordsStreamName :: StreamName
    , putRecordsSequenceNumberForOrdering :: !(Maybe SequenceNumber)
    } deriving Show

data PutRecordsResponseRecord
    = PutRecordsResponseRecord SequenceNumber ShardId
    | PutRecordsResponseRecordFailed T.Text
    deriving Show

data PutRecordsResponse
    = PutRecordsResponse
    { putRecordsResponseRecords :: ![PutRecordsResponseRecord]
    } deriving Show

instance ToJSON PutRecordsItem where
    toJSON PutRecordsItem{..} = object $
        [ "Data" .= T.decodeUtf8 (B64.encode putRecordsItemData)
        , "ExplicitHashKey" .= putRecordsItemExplicitHashKey
        , "PartitionKey" .= putRecordsItemPartitionKey
        ]

instance ToJSON PutRecords where
    toJSON PutRecords{..} = object
        [ "Records" .= putRecordsRecords
        , "StreamName" .= putRecordsStreamName
        , "SequenceNumberForOrdering" .= putRecordsSequenceNumberForOrdering
        ]

instance FromJSON PutRecordsResponseRecord where
    parseJSON (Object xs) = parseSuccess <|> parseFailure
        where
            parseSuccess =
                PutRecordsResponseRecord
                    <$> xs .: "SequenceNumber"
                    <*> xs .: "ShardId"
            parseFailure =
                PutRecordsResponseRecordFailed
                    <$> xs .: "Message"
    parseJSON _ = fail "PutRecordsResponseRecord expected object"

instance FromJSON PutRecordsResponse where
    parseJSON (Object xs) = do
        putRecordsResponseRecords <- xs .: "Records"
        return PutRecordsResponse{..}
    parseJSON _ = fail "PutRecordsResponse expected object"

instance Transaction PutRecords PutRecordsResponse where

instance ResponseConsumer r PutRecordsResponse where
    type ResponseMetadata PutRecordsResponse = KinesisMetadata
    responseConsumer _ = kinesisResponseConsumer

instance AsMemoryResponse PutRecordsResponse where
    type MemoryResponse PutRecordsResponse = PutRecordsResponse
    loadToMemory = return

instance SignQuery PutRecords where
    type ServiceConfiguration PutRecords = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = KinesisPutRecords
        , kinesisQueryBody = Just $ BL.toStrict $ encode cmd
        }
