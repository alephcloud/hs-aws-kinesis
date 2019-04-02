-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.CreateStream
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
-- Module: Aws.Kinesis.Commands.CreateStream
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation adds a new Amazon Kinesis stream to your AWS account. A
-- stream captures and transports data records that are continuously emitted
-- from different data sources or producers. Scale-out within an Amazon Kinesis
-- stream is explicitly supported by means of shards, which are uniquely
-- identified groups of data records in an Amazon Kinesis stream.
--
-- You specify and control the number of shards that a stream is composed of.
-- Each open shard can support up to 5 read transactions per second, up to a
-- maximum total of 2 MB of data read per second. Each shard can support up to
-- 1000 write transactions per second, up to a maximum total of 1 MB data
-- written per second. You can add shards to a stream if the amount of data
-- input increases and you can remove shards if the amount of data input
-- decreases.
--
-- The stream name identifies the stream. The name is scoped to the AWS account
-- used by the application. It is also scoped by region. That is, two streams
-- in two different accounts can have the same name, and two streams in the
-- same account, but in two different regions, can have the same name.
--
-- CreateStream is an asynchronous operation. Upon receiving a CreateStream
-- request, Amazon Kinesis immediately returns and sets the stream status to
-- CREATING. After the stream is created, Amazon Kinesis sets the stream status
-- to ACTIVE. You should perform read and write operations only on an ACTIVE
-- stream.
--
-- You receive a LimitExceededException when making a CreateStream request if
-- you try to do one of the following:
--
-- Have more than five streams in the CREATING state at any point in time.
-- Create more shards than are authorized for your account. Note: The default
-- limit for an AWS account is 10 shards per stream. If you need to create a
-- stream with more than 10 shards, contact AWS Support to increase the limit
-- on your account.
--
-- You can use the DescribeStream operation to check the stream status, which
-- is returned in StreamStatus.
--
-- CreateStream has a limit of 5 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_CreateStream.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DeriveDataTypeable #-}

module Aws.Kinesis.Commands.CreateStream
( CreateStream(..)
, CreateStreamResponse(..)
, CreateStreamExceptions(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

import GHC.Generics

createStreamAction :: KinesisAction
createStreamAction = KinesisCreateStream

data CreateStream = CreateStream
    { createStreamShardCound :: !Int
    -- ^ The number of shards that the stream will use. The throughput of the
    -- stream is a function of the number of shards; more shards are required
    -- for greater provisioned throughput.
    --
    -- Note: The default limit for an AWS account is 10 shards per stream. If
    -- you need to create a stream with more than 10 shards, contact AWS
    -- Support to increase the limit on your account.
    --
    -- Note that this limit is not checked by the code.

    , createStreamStreamName :: !StreamName
    -- ^ A name to identify the stream.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData CreateStream

instance ToJSON CreateStream where
    toJSON CreateStream{..} = object
        [ "ShardCount" .= createStreamShardCound
        , "StreamName" .= createStreamStreamName
        ]

data CreateStreamResponse = CreateStreamResponse
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData CreateStreamResponse

instance ResponseConsumer r CreateStreamResponse where
    type ResponseMetadata CreateStreamResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance FromJSON CreateStreamResponse where
    parseJSON _ = return CreateStreamResponse

instance SignQuery CreateStream where
    type ServiceConfiguration CreateStream = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = createStreamAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction CreateStream CreateStreamResponse

instance AsMemoryResponse CreateStreamResponse where
    type MemoryResponse CreateStreamResponse = CreateStreamResponse
    loadToMemory = return

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data CreateStreamExceptions
    = CreateStreamInvalidArgumentException
    -- ^ /Code 400/

    | CreateStreamLimitExceededException
    -- ^ /Code 400/

    | CreateStreamResourceInUseException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData CreateStreamExceptions

