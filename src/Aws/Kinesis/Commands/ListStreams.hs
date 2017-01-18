-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.ListStreams
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
-- Module: Aws.Kinesis.Commands.ListStreams
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation returns an array of the names of all the streams that are
-- associated with the AWS account making the ListStreams request. A given AWS
-- account can have many streams active at one time.
--
-- The number of streams may be too large to return from a single call to
-- ListStreams. You can limit the number of returned streams using the Limit
-- parameter. If you do not specify a value for the Limit parameter, Amazon
-- Kinesis uses the default limit, which is currently 10.
--
-- You can detect if there are more streams available to list by using the
-- HasMoreStreams flag from the returned output. If there are more streams
-- available, you can request more streams by using the name of the last stream
-- returned by the ListStreams request in the ExclusiveStartStreamName
-- parameter in a subsequent request to ListStreams. The group of stream names
-- returned by the subsequent request is then added to the list. You can
-- continue this process until all the stream names have been collected in the
-- list.
--
-- ListStreams has a limit of 5 transactions per second per account.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_ListStreams.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.ListStreams
( ListStreams(..)
, ListStreamsResponse(..)
, ListStreamsExceptions(..)
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
import Data.Maybe
import Data.Typeable

import GHC.Generics

listStreamsAction :: KinesisAction
listStreamsAction = KinesisListStreams

data ListStreams = ListStreams
    { listStreamsExclusiveStartStreamName :: !(Maybe StreamName)
    -- ^ The name of the stream to start the list with.

    , listStreamsLimit :: !(Maybe Int)
    -- ^ The maximum number of streams to list.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData ListStreams

instance ToJSON ListStreams where
    toJSON ListStreams{..} = object
        [ "ExclusiveStartStreamName" .= listStreamsExclusiveStartStreamName
        , "StreamName" .= listStreamsLimit
        ]

data ListStreamsResponse = ListStreamsResponse
    { listStreamsResHasMoreStreams :: !Bool
    -- ^ If set to true, there are more streams available to list.

    , listStreamsResStreamNames :: ![StreamName]
    -- ^ The names of the streams that are associated with the AWS account
    -- making the ListStreams request.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData ListStreamsResponse

instance FromJSON ListStreamsResponse where
    parseJSON = withObject "ListStreamsResponse" $ \o -> ListStreamsResponse
        <$> o .: "HasMoreStreams"
        <*> o .: "StreamNames"

instance ResponseConsumer r ListStreamsResponse where
    type ResponseMetadata ListStreamsResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance SignQuery ListStreams where
    type ServiceConfiguration ListStreams = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = listStreamsAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction ListStreams ListStreamsResponse

instance AsMemoryResponse ListStreamsResponse where
    type MemoryResponse ListStreamsResponse = ListStreamsResponse
    loadToMemory = return

instance ListResponse ListStreamsResponse StreamName where
    listResponse (ListStreamsResponse _ streams) = streams

-- | This instance assumes that 'ListStreams' returns at least one
-- stream if available, i.e. if @listStreamsResHasMoreStreams == True@.
--
-- Otherwise, in case no stream is returned but
-- @listStreamsResHasMoreStreams == True@ the implementation in this instance
-- returns Nothing, thus ignoring the value of 'listStreamsResHasMoreStreams'.
-- The alternatives would be to either throw an exception or to start over
-- with a reqeust for the first set of streams which could result in a
-- non-terminating behavior.
--
-- The request parameter 'listStreamsLimit' is interpreted as limit for each
-- single request and not for the overall transaction.
--
instance IteratedTransaction ListStreams ListStreamsResponse where
    nextIteratedRequest req@ListStreams{..} ListStreamsResponse{..}
        | listStreamsResHasMoreStreams && isJust exclStartStream = Just req
            { listStreamsExclusiveStartStreamName = exclStartStream
            }
        | otherwise = Nothing
      where
        exclStartStream = case listStreamsResStreamNames of
            [] -> Nothing
            t -> Just $ last t

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data ListStreamsExceptions
    = ListStreamsLimitExceededException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData ListStreamsExceptions

