-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.DeleteStream
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
-- Module: Aws.Kinesis.Commands.DeleteStream
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation deletes a stream and all of its shards and data. You must
-- shut down any applications that are operating on the stream before you
-- delete the stream. If an application attempts to operate on a deleted
-- stream, it will receive the exception ResourceNotFoundException.
--
-- If the stream is in the ACTIVE state, you can delete it. After a
-- DeleteStream request, the specified stream is in the DELETING state until
-- Amazon Kinesis completes the deletion.
--
-- Note: Amazon Kinesis might continue to accept data read and write
-- operations, such as PutRecord and GetRecords, on a stream in the DELETING
-- state until the stream deletion is complete.
--
-- When you delete a stream, any shards in that stream are also deleted.
--
-- You can use the DescribeStream operation to check the state of the stream,
-- which is returned in StreamStatus.
--
-- DeleteStream has a limit of 5 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_DeleteStream.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.DeleteStream
( DeleteStream(..)
, DeleteStreamResponse(..)
, DeleteStreamExceptions(..)
) where

import Aws.Core
import Aws.Kinesis.Core
import Aws.Kinesis.Types

import Control.DeepSeq

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

import GHC.Generics

deleteStreamAction :: KinesisAction
deleteStreamAction = KinesisDeleteStream

data DeleteStream = DeleteStream
    { deleteStreamStreamName :: !StreamName
    -- ^ The name of the stream to delete.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData DeleteStream

instance ToJSON DeleteStream where
    toJSON DeleteStream{..} = object
        [ "StreamName" .= deleteStreamStreamName
        ]

data DeleteStreamResponse = DeleteStreamResponse
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData DeleteStreamResponse

instance FromJSON DeleteStreamResponse where
    parseJSON _ = return DeleteStreamResponse

instance ResponseConsumer r DeleteStreamResponse where
    type ResponseMetadata DeleteStreamResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance SignQuery DeleteStream where
    type ServiceConfiguration DeleteStream = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = deleteStreamAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction DeleteStream DeleteStreamResponse

instance AsMemoryResponse DeleteStreamResponse where
    type MemoryResponse DeleteStreamResponse = DeleteStreamResponse
    loadToMemory = return

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data DeleteStreamExceptions
    = DeleteStreamLimitExceededException
    -- ^ /Code 400/

    | DeleteStreamResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData DeleteStreamExceptions

