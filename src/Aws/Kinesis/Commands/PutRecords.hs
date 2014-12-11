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
-- /API Version: 2013-12-02/
--
-- Puts (writes) multiple data records from a producer into an Amazon Kinesis
-- stream in a single call (also referred to as a PutRecords request). Use this
-- operation to send data from a data producer into the Amazon Kinesis stream
-- for real-time ingestion and processing. Each shard can support up to 1000
-- records written per second, up to a maximum total of 1 MB data written per
-- second.
--
-- You must specify the name of the stream that captures, stores, and
-- transports the data; and an array of request Records, with each record in
-- the array requiring a partition key and data blob.
--
-- The data blob can be any type of data; for example, a segment from a log
-- file, geographic/location data, website clickstream data, and so on.
--
-- The partition key is used by Amazon Kinesis as input to a hash function that
-- maps the partition key and associated data to a specific shard. An MD5 hash
-- function is used to map partition keys to 128-bit integer values and to map
-- associated data records to shards. As a result of this hashing mechanism,
-- all data records with the same partition key map to the same shard within
-- the stream. For more information, see Partition Key in the Amazon Kinesis
-- Developer Guide.
--
-- Each record in the Records array may include an optional parameter,
-- ExplicitHashKey, which overrides the partition key to shard mapping. This
-- parameter allows a data producer to determine explicitly the shard where the
-- record is stored. For more information, see Adding Multiple Records with
-- PutRecords in the Amazon Kinesis Developer Guide.
--
-- The PutRecords response includes an array of response Records. Each record
-- in the response array directly correlates with a record in the request array
-- using natural ordering, from the top to the bottom of the request and
-- response. The response Records array always includes the same number of
-- records as the request array.
--
-- The response Records array includes both successfully and unsuccessfully
-- processed records. Amazon Kinesis attempts to process all records in each
-- PutRecords request. A single record failure does not stop the processing of
-- subsequent records.
--
-- A successfully-processed record includes ShardId and SequenceNumber values.
-- The ShardId parameter identifies the shard in the stream where the record is
-- stored. The SequenceNumber parameter is an identifier assigned to the put
-- record, unique to all records in the stream.
--
-- An unsuccessfully-processed record includes ErrorCode and ErrorMessage
-- values. ErrorCode reflects the type of error and can be one of the following
-- values: ProvisionedThroughputExceededException or InternalFailure.
-- ErrorMessage provides more detailed information about the
-- ProvisionedThroughputExceededException exception including the account ID,
-- stream name, and shard ID of the record that was throttled.
--
-- Data records are accessible for only 24 hours from the time that they are
-- added to an Amazon Kinesis stream.
--
-- <http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html>
--
module Aws.Kinesis.Commands.PutRecords
( PutRecords(..)
, PutRecordsRequestEntry(..)
, PutRecordsResponse(..)
, PutRecordsResponseRecord(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types
import Data.Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Base64 as B64
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

data PutRecordsRequestEntry = PutRecordsRequestEntry
    { putRecordsRequestEntryData :: !BS.ByteString
    , putRecordsRequestEntryExplicitHashKey :: !(Maybe PartitionHash)
    , putRecordsRequestEntryPartitionKey :: !PartitionKey
    } deriving Show

data PutRecords = PutRecords
    { putRecordsRecords :: ![PutRecordsRequestEntry]
    , putRecordsStreamName :: !StreamName
    } deriving Show

data PutRecordsResponseRecord = PutRecordsResponseRecord
    { putRecordsResponseRecordErrorCode :: !(Maybe T.Text)
    , putRecordsResponseRecordErrorMessage :: !(Maybe T.Text)
    , putRecordsResponseRecordSequenceNumber :: !(Maybe SequenceNumber)
    , putRecordsResponseRecordShardId :: !(Maybe ShardId)
    } deriving Show

data PutRecordsResponse
    = PutRecordsResponse
    { putRecordsResponseFailedRecordCount :: !Int
    , putRecordsResponseRecords :: ![PutRecordsResponseRecord]
    } deriving Show

instance ToJSON PutRecordsRequestEntry where
    toJSON PutRecordsRequestEntry{..} = object $
        [ "Data" .= T.decodeUtf8 (B64.encode putRecordsRequestEntryData)
        , "ExplicitHashKey" .= putRecordsRequestEntryExplicitHashKey
        , "PartitionKey" .= putRecordsRequestEntryPartitionKey
        ]

instance ToJSON PutRecords where
    toJSON PutRecords{..} = object
        [ "Records" .= putRecordsRecords
        , "StreamName" .= putRecordsStreamName
        ]

instance FromJSON PutRecordsResponseRecord where
    parseJSON = withObject "PutRecordsResponseRecord" $ \o -> do
        putRecordsResponseRecordErrorCode <- o .:? "ErrorCode"
        putRecordsResponseRecordErrorMessage <- o .:? "ErrorMessage"
        putRecordsResponseRecordSequenceNumber <- o .:? "SequenceNumber"
        putRecordsResponseRecordShardId <- o .:? "ShardId"
        return PutRecordsResponseRecord{..}

instance FromJSON PutRecordsResponse where
    parseJSON = withObject "PutRecordsResponse" $ \o -> do
        putRecordsResponseFailedRecordCount <- o .: "FailedRecordCount"
        putRecordsResponseRecords <- o .: "Records"
        return PutRecordsResponse{..}

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
