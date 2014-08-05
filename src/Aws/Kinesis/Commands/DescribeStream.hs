{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- |
-- Module: Aws.Sns.Commands.DescribeStream
-- Copyright: Copyright © 2014 AlephCloud Systems, Inc.
-- License: MIT
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
--
module Aws.Kinesis.Commands.DescribeStream
( DescribeStream(..)
, DescribeStreamResponse(..)
, DescribeStreamExceptions(..)
) where

import Control.Applicative

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

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
    deriving (Show, Read, Eq, Ord, Typeable)

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
    deriving (Show, Read, Eq, Ord, Typeable)

instance ResponseConsumer r DescribeStreamResponse where
    type ResponseMetadata DescribeStreamResponse = KinesisMetadata
    responseConsumer _ = kinesisResponseConsumer

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

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable)


