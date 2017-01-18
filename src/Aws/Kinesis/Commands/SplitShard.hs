-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.SplitShard
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
-- Module: Aws.Kinesis.Commands.SplitShard
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-03-31/
-- This operation splits a shard into two new shards in the stream, to increase
-- the stream's capacity to ingest and transport data. SplitShard is called
-- when there is a need to increase the overall capacity of stream because of
-- an expected increase in the volume of data records being ingested.
--
-- SplitShard can also be used when a given shard appears to be approaching its
-- maximum utilization, for example, when the set of producers sending data
-- into the specific shard are suddenly sending more than previously
-- anticipated. You can also call the SplitShard operation to increase stream
-- capacity, so that more Amazon Kinesis applications can simultaneously read
-- data from the stream for real-time processing.
--
-- The SplitShard operation requires that you specify the shard to be split and
-- the new hash key, which is the position in the shard where the shard gets
-- split in two. In many cases, the new hash key might simply be the average of
-- the beginning and ending hash key, but it can be any hash key value in the
-- range being mapped into the shard. For more information about splitting
-- shards, see the Amazon Kinesis Developer Guide.
--
-- You can use the DescribeStream operation to determine the shard ID and hash
-- key values for the ShardToSplit and NewStartingHashKey parameters that are
-- specified in the SplitShard request.
--
-- SplitShard is an asynchronous operation. Upon receiving a SplitShard
-- request, Amazon Kinesis immediately returns a response and sets the stream
-- status to UPDATING. After the operation is completed, Amazon Kinesis sets
-- the stream status to ACTIVE. Read and write operations continue to work
-- while the stream is in the UPDATING state.
--
-- You can use DescribeStream to check the status of the stream, which is
-- returned in StreamStatus. If the stream is in the ACTIVE state, you can call
-- SplitShard. If a stream is in CREATING or UPDATING or DELETING states, then
-- Amazon Kinesis returns a ResourceInUseException.
--
-- If the specified stream does not exist, Amazon Kinesis returns a
-- ResourceNotFoundException. If you try to create more shards than are
-- authorized for your account, you receive a LimitExceededException.
--
-- Note: The default limit for an AWS account is 10 shards per stream. If you
-- need to create a stream with more than 10 shards, contact AWS Support to
-- increase the limit on your account.
--
-- If you try to operate on too many streams in parallel using CreateStream,
-- DeleteStream, MergeShards or SplitShard, you will receive a
-- LimitExceededException.
--
-- SplitShard has limit of 5 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_SplitShard.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.SplitShard
( SplitShard(..)
, SplitShardResponse(..)
, SplitShardExceptions(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

import GHC.Generics

splitShardAction :: KinesisAction
splitShardAction = KinesisSplitShard

data SplitShard = SplitShard
    { splitShardNewStartingHashKey :: !PartitionHash
    -- ^ A hash key value for the starting hash key of one of the child shards
    -- created by the split. The hash key range for a given shard constitutes a
    -- set of ordered contiguous positive integers. The value for
    -- NewStartingHashKey must be in the range of hash keys being mapped into
    -- the shard. The NewStartingHashKey hash key value and all higher hash key
    -- values in hash key range are distributed to one of the child shards. All
    -- the lower hash key values in the range are distributed to the other
    -- child shard.

    , splitShardShardToSplit :: !ShardId
    -- ^ The shard ID of the shard to split.

    , splitShardStreamName :: !StreamName
    -- ^ The name of the stream for the shard split.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData SplitShard

instance ToJSON SplitShard where
    toJSON SplitShard{..} = object
        [ "NewStartingHashKey" .= splitShardNewStartingHashKey
        , "ShardToSplit" .= splitShardShardToSplit
        , "StreamName" .= splitShardStreamName
        ]

data SplitShardResponse = SplitShardResponse
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData SplitShardResponse

instance ResponseConsumer r SplitShardResponse where
    type ResponseMetadata SplitShardResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance FromJSON SplitShardResponse where
    parseJSON _ = return SplitShardResponse

instance SignQuery SplitShard where
    type ServiceConfiguration SplitShard = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = splitShardAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction SplitShard SplitShardResponse

instance AsMemoryResponse SplitShardResponse where
    type MemoryResponse SplitShardResponse = SplitShardResponse
    loadToMemory = return

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data SplitShardExceptions
    = SplitShardInvalidArgumentException
    -- ^ /Code 400/

    | SplitShardLimitExceededException
    -- ^ /Code 400/

    | SplitShardResourceInUseException
    -- ^ /Code 400/

    | SplitShardResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData SplitShardExceptions

