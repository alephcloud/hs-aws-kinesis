-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.DescribeStream
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
-- Module: Aws.Kinesis.Commands.DescribeStream
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-03-31/
--
-- This operation returns the following information about the stream: the
-- current status of the stream, the stream Amazon Resource Name (ARN), and an
-- array of shard objects that comprise the stream. For each shard object there
-- is information about the hash key and sequence number ranges that the shard
-- spans, and the IDs of any earlier shards that played in a role in a
-- MergeShards or SplitShard operation that created the shard. A sequence
-- number is the identifier associated with every record ingested in the Amazon
-- Kinesis stream. The sequence number is assigned by the Amazon Kinesis
-- service when a record is put into the stream.
--
-- You can limit the number of returned shards using the Limit parameter. The
-- number of shards in a stream may be too large to return from a single call
-- to DescribeStream. You can detect this by using the HasMoreShards flag in
-- the returned output. HasMoreShards is set to true when there is more data
-- available.
--
-- If there are more shards available, you can request more shards by using the
-- shard ID of the last shard returned by the DescribeStream request, in the
-- ExclusiveStartShardId parameter in a subsequent request to DescribeStream.
-- DescribeStream is a paginated operation.
--
-- DescribeStream has a limit of 10 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_DescribeStream.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.DescribeStream
( DescribeStream(..)
, DescribeStreamResponse(..)
, DescribeStreamExceptions(..)
) where

#ifndef MIN_VERSION_base
#define MIN_VERSION_base(x,y,z) 1
#endif

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

#if ! MIN_VERSION_base(4,8,0)
import Control.Applicative
#endif
import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Maybe
import Data.Typeable

import GHC.Generics

describeStreamAction :: KinesisAction
describeStreamAction = KinesisDescribeStream

data DescribeStream = DescribeStream
    { describeStreamExclusiveStartShardId:: !(Maybe ShardId)
    -- ^ The shard ID of the shard to start with for the stream description.

    , describeStreamLimit :: !(Maybe Int)
    -- ^ The maximum number of shards to return.

    , describeStreamStreamName :: !StreamName
    -- ^ The name of the stream to describe.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData DescribeStream

instance ToJSON DescribeStream where
    toJSON DescribeStream{..} = object
        [ "ExclusiveStartShardId" .= describeStreamExclusiveStartShardId
        , "Limit" .= describeStreamLimit
        , "StreamName" .= describeStreamStreamName
        ]

data DescribeStreamResponse = DescribeStreamResponse
    { describeStreamResStreamDescription :: !StreamDescription
    -- ^ Contains the current status of the stream, the stream ARN, an array of
    -- shard objects that comprise the stream, and states whether there are
    -- more shards available.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData DescribeStreamResponse

instance ResponseConsumer r DescribeStreamResponse where
    type ResponseMetadata DescribeStreamResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance FromJSON DescribeStreamResponse where
    parseJSON = withObject "DescribeStreamResponse" $ \o -> DescribeStreamResponse
        <$> o .: "StreamDescription"

instance SignQuery DescribeStream where
    type ServiceConfiguration DescribeStream = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = describeStreamAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction DescribeStream DescribeStreamResponse

instance AsMemoryResponse DescribeStreamResponse where
    type MemoryResponse DescribeStreamResponse = DescribeStreamResponse
    loadToMemory = return

instance ListResponse DescribeStreamResponse Shard where
    listResponse DescribeStreamResponse{..} =
        streamDescriptionShards describeStreamResStreamDescription

-- | This instance assumes that the returned 'StreamDescription' contains at least one
-- shard if available, i.e. if @streamDescriptionResHasMoreShards == True@.
--
-- Otherwise, in case no shard is returned but
-- @streamDescriptionHasMoreShards == True@ the implementation in this instance
-- returns Nothing, thus ignoring the value of 'streamDescriptionHasMoreShards'.
-- The alternatives would be to either throw an exception or to start over
-- with a reqeust for the first set of shards which could result in a
-- non-terminating behavior.
--
-- The request parameter 'describeStreamLimit' is interpreted as limit for each
-- single request and not for the overall transaction.
--
instance IteratedTransaction DescribeStream DescribeStreamResponse where
    nextIteratedRequest req@DescribeStream{..} res
        | streamDescriptionHasMoreShards streamDesc && isJust exclStartShardId = Just req
            { describeStreamExclusiveStartShardId = exclStartShardId
            }
        | otherwise = Nothing
      where
        streamDesc = describeStreamResStreamDescription res
        exclStartShardId = case streamDescriptionShards streamDesc of
            [] -> Nothing
            t -> Just . shardShardId . last $ t

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data DescribeStreamExceptions
    = DescribeStreamLimitExceededException
    -- ^ /Code 400/

    | DescribeStreamResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData DescribeStreamExceptions

