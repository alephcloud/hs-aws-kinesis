-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.GetShardIterator
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
-- Module: Aws.Kinesis.Commands.GetShardIterator
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation returns a shard iterator in ShardIterator. The shard iterator
-- specifies the position in the shard from which you want to start reading
-- data records sequentially. A shard iterator specifies this position using
-- the sequence number of a data record in a shard. A sequence number is the
-- identifier associated with every record ingested in the Amazon Kinesis
-- stream. The sequence number is assigned by the Amazon Kinesis service when a
-- record is put into the stream.
--
-- You must specify the shard iterator type in the GetShardIterator request.
-- For example, you can set the ShardIteratorType parameter to read exactly
-- from the position denoted by a specific sequence number by using the
-- AT_SEQUENCE_NUMBER shard iterator type, or right after the sequence number
-- by using the AFTER_SEQUENCE_NUMBER shard iterator type, using sequence
-- numbers returned by earlier PutRecord, GetRecords or DescribeStream
-- requests. You can specify the shard iterator type TRIM_HORIZON in the
-- request to cause ShardIterator to point to the last untrimmed record in the
-- shard in the system, which is the oldest data record in the shard. Or you
-- can point to just after the most recent record in the shard, by using the
-- shard iterator type LATEST, so that you always read the most recent data in
-- the shard.
--
-- Note: Each shard iterator expires five minutes after it is returned to the
-- requester.
--
-- When you repeatedly read from an Amazon Kinesis stream use a
-- GetShardIterator request to get the first shard iterator to to use in your
-- first GetRecords request and then use the shard iterator returned by the
-- GetRecords request in NextShardIterator for subsequent reads. A new shard
-- iterator is returned by every GetRecords request in NextShardIterator, which
-- you use in the ShardIterator parameter of the next GetRecords request.
--
-- If a GetShardIterator request is made too often, you will receive a
-- ProvisionedThroughputExceededException. For more information about
-- throughput limits, see the Amazon Kinesis Developer Guide.
--
-- GetShardIterator can return null for its ShardIterator to indicate that the
-- shard has been closed and that the requested iterator will return no more
-- data. A shard can be closed by a SplitShard or MergeShards operation.
--
-- GetShardIterator has a limit of 5 transactions per second per account per
-- open shard.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_GetShardIterator.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}

module Aws.Kinesis.Commands.GetShardIterator
( GetShardIterator(..)
, GetShardIteratorResponse(..)
, GetShardIteratorExceptions(..)
) where

#ifndef MIN_VERSION_base
#define MIN_VERSION_base(x,y,z) 1
#endif

import Aws.Core
import Aws.Kinesis.Types
import Aws.Kinesis.Core

#if ! MIN_VERSION_base(4,8,0)
import Control.Applicative
#endif
import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

import GHC.Generics

getShardIteratorAction :: KinesisAction
getShardIteratorAction = KinesisGetShardIterator

data GetShardIterator = GetShardIterator
    { getShardIteratorShardId :: !ShardId
    -- ^ The shard ID of the shard to get the iterator for.

    , getShardIteratorShardIteratorType :: !ShardIteratorType
    -- ^ Determines how the shard iterator is used to start reading data
    -- records from the shard.

    , getShardIteratorStartingSequenceNumber :: !(Maybe SequenceNumber)
    -- ^ The sequence number of the data record in the shard from which to
    -- start reading from.

    , getShardIteratorStreamName :: !StreamName
    -- ^ The name of the stream.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData GetShardIterator

instance ToJSON GetShardIterator where
    toJSON GetShardIterator{..} = object
        [ "ShardId" .= getShardIteratorShardId
        , "ShardIteratorType" .= getShardIteratorShardIteratorType
        , "StartingSequenceNumber" .= getShardIteratorStartingSequenceNumber
        , "StreamName" .= getShardIteratorStreamName
        ]

data GetShardIteratorResponse = GetShardIteratorResponse
    { getShardIteratorResShardIterator :: !ShardIterator
    -- ^ The position in the shard from which to start reading data records
    -- sequentially. A shard iterator specifies this position using the
    -- sequence number of a data record in a shard.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData GetShardIteratorResponse

instance FromJSON GetShardIteratorResponse where
    parseJSON = withObject "GetShardIteratorResponse" $ \o -> GetShardIteratorResponse
        <$> o .: "ShardIterator"

instance ResponseConsumer r GetShardIteratorResponse where
    type ResponseMetadata GetShardIteratorResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance SignQuery GetShardIterator where
    type ServiceConfiguration GetShardIterator = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = getShardIteratorAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction GetShardIterator GetShardIteratorResponse

instance AsMemoryResponse GetShardIteratorResponse where
    type MemoryResponse GetShardIteratorResponse = GetShardIteratorResponse
    loadToMemory = return

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data GetShardIteratorExceptions
    = GetShardIteratorInvalidArgumentException
    -- ^ /Code 400/

    | GetShardIteratorProvisionedThroughputExceededException
    -- ^ /Code 400/

    | GetShardIteratorResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData GetShardIteratorExceptions

