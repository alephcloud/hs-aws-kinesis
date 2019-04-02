-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.MergeShards
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
-- Module: Aws.Kinesis.Commands.MergeShards
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation merges two adjacent shards in a stream and combines them into
-- a single shard to reduce the stream's capacity to ingest and transport data.
-- Two shards are considered adjacent if the union of the hash key ranges for
-- the two shards form a contiguous set with no gaps. For example, if you have
-- two shards, one with a hash key range of 276...381 and the other with a hash
-- key range of 382...454, then you could merge these two shards into a single
-- shard that would have a hash key range of 276...454. After the merge, the
-- single child shard receives data for all hash key values covered by the two
-- parent shards.
--
-- MergeShards is called when there is a need to reduce the overall capacity of
-- a stream because of excess capacity that is not being used. The operation
-- requires that you specify the shard to be merged and the adjacent shard for
-- a given stream. For more information about merging shards, see the Amazon
-- Kinesis Developer Guide.
--
-- If the stream is in the ACTIVE state, you can call MergeShards. If a stream
-- is in CREATING or UPDATING or DELETING states, then Amazon Kinesis returns a
-- ResourceInUseException. If the specified stream does not exist, Amazon
-- Kinesis returns a ResourceNotFoundException.
--
-- You can use the DescribeStream operation to check the state of the stream,
-- which is returned in StreamStatus.
--
-- MergeShards is an asynchronous operation. Upon receiving a MergeShards
-- request, Amazon Kinesis immediately returns a response and sets the
-- StreamStatus to UPDATING. After the operation is completed, Amazon Kinesis
-- sets the StreamStatus to ACTIVE. Read and write operations continue to work
-- while the stream is in the UPDATING state.
--
-- You use the DescribeStream operation to determine the shard IDs that are
-- specified in the MergeShards request.
--
-- If you try to operate on too many streams in parallel using CreateStream,
-- DeleteStream, MergeShards or SplitShard, you will receive a
-- LimitExceededException.
--
-- MergeShards has limit of 5 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_MergeShards.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.MergeShards
( MergeShards(..)
, MergeShardsResponse(..)
, MergeShardsExceptions(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

import GHC.Generics

mergeShardsAction :: KinesisAction
mergeShardsAction = KinesisMergeShards

data MergeShards = MergeShards
    { mergeShardsAdjacentShardToMerge :: !ShardId
    -- ^ The shard ID of the adjacent shard for the merge.

    , mergeShardsShardToMerge :: !ShardId
    -- ^ The shard ID of the shard to combine with the adjacent shard for the
    -- merge.

    , mergeShardsStreamName :: !StreamName
    -- ^ The name of the stream for the merge.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData MergeShards

instance ToJSON MergeShards where
    toJSON MergeShards{..} = object
        [ "AdjacentShardToMerge" .= mergeShardsAdjacentShardToMerge
        , "ShardToMerge" .= mergeShardsShardToMerge
        , "StreamName" .= mergeShardsStreamName
        ]

data MergeShardsResponse = MergeShardsResponse
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData MergeShardsResponse

instance ResponseConsumer r MergeShardsResponse where
    type ResponseMetadata MergeShardsResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance FromJSON MergeShardsResponse where
    parseJSON _ = return MergeShardsResponse

instance SignQuery MergeShards where
    type ServiceConfiguration MergeShards = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = mergeShardsAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction MergeShards MergeShardsResponse

instance AsMemoryResponse MergeShardsResponse where
    type MemoryResponse MergeShardsResponse = MergeShardsResponse
    loadToMemory = return

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data MergeShardsExceptions
    = MergeShardsInvalidArgumentException
    -- ^ /Code 400/

    | MergeShardsLimitExceededException
    -- ^ /Code 400/

    | MergeShardsResourceInUseException
    -- ^ /Code 400/

    | MergeShardsResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData MergeShardsExceptions

