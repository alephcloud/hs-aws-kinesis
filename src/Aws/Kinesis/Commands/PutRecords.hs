-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.PutRecords
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
-- Module: Aws.Kinesis.Commands.PutRecords
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
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

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}

module Aws.Kinesis.Commands.PutRecords
( PutRecords(..)
, PutRecordsRequestEntry(..)
, PutRecordsResponse(..)
, PutRecordsResponseRecord(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Base64 as B64
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Data.Typeable

import GHC.Generics

-- | Represents a single record in a 'PutRecords' request.
--
data PutRecordsRequestEntry = PutRecordsRequestEntry
    { putRecordsRequestEntryData :: !BS.ByteString
    -- ^ The data blob to be put into the record. The maximum size of the data
    -- blob is 50 kilobytes.

    , putRecordsRequestEntryExplicitHashKey :: !(Maybe PartitionHash)
    -- ^ The hash value used to determine explicitly the shard that the data
    -- record is assigned to by overriding the partition key hash.

    , putRecordsRequestEntryPartitionKey :: !PartitionKey
    -- ^ Determines which shard in the stream the data record is assigned to.
    -- All data records with the same partition key map to the same shard.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData PutRecordsRequestEntry

-- | The body of the 'PutRecords' request.
--
data PutRecords = PutRecords
    { putRecordsRecords :: ![PutRecordsRequestEntry]
    -- ^ The records associated with the request. Minimum of 1 item, maximum
    -- 500.

    , putRecordsStreamName :: !StreamName
    -- ^ The stream name associated with the request.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData PutRecords

-- | Represents the result for a single record in a 'PutRecordsResponse'.
--
data PutRecordsResponseRecord = PutRecordsResponseRecord
    { putRecordsResponseRecordErrorCode :: !(Maybe T.Text)
    -- ^ If the request did not succeed, an error code will be provided.

    , putRecordsResponseRecordErrorMessage :: !(Maybe T.Text)
    -- ^ If the request did not succeed, an error message will be provided.

    , putRecordsResponseRecordSequenceNumber :: !(Maybe SequenceNumber)
    -- ^ The sequence number assigned to the (sucessfully processed) record.

    , putRecordsResponseRecordShardId :: !(Maybe ShardId)
    -- ^ The shard ID assigned to the (successfully processed) record.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData PutRecordsResponseRecord

data PutRecordsResponse = PutRecordsResponse
    { putRecordsResponseFailedRecordCount :: !Int
    -- ^ The number of unsuccessfully processed records in a 'PutRecords'
    -- request.

    , putRecordsResponseRecords :: ![PutRecordsResponseRecord]
    -- ^ An array of successfully and unsuccessfully processed records,
    -- correlated with the request by natural ordering.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData PutRecordsResponse

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
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance AsMemoryResponse PutRecordsResponse where
    type MemoryResponse PutRecordsResponse = PutRecordsResponse
    loadToMemory = return

instance SignQuery PutRecords where
    type ServiceConfiguration PutRecords = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = KinesisPutRecords
        , kinesisQueryBody = Just $ BL.toStrict $ encode cmd
        }
