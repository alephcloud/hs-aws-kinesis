{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- |
-- Module: Aws.Kinesis.Commands.ListStreams
-- Copyright: Copyright © 2014 AlephCloud Systems, Inc.
-- License: MIT
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
--
module Aws.Kinesis.Commands.ListStreams
( ListStreams(..)
, ListStreamsResponse(..)
, ListStreamsExceptions(..)
) where

import Aws.Core
import Aws.Kinesis.Types
import Aws.Kinesis.Core

import Control.Applicative

import Data.Aeson
import qualified Data.ByteString.Lazy as LB
import Data.Typeable

listStreamsAction :: KinesisAction
listStreamsAction = KinesisListStreams

data ListStreams = ListStreams
    { listStreamsExclusiveStartStreamName :: !(Maybe StreamName)
    -- ^ The name of the stream to start the list with.

    , listStreamsLimit :: !(Maybe Int)
    -- ^ The maximum number of streams to list.
    }
    deriving (Show, Read, Eq, Ord, Typeable)

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
    deriving (Show, Read, Eq, Ord, Typeable)

instance FromJSON ListStreamsResponse where
    parseJSON = withObject "ListStreamsResponse" $ \o -> ListStreamsResponse
        <$> o .: "HasMoreStreams"
        <*> o .: "StreamNames"

instance ResponseConsumer r ListStreamsResponse where
    type ResponseMetadata ListStreamsResponse = KinesisMetadata
    responseConsumer _ = kinesisResponseConsumer

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

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data ListStreamsExceptions
    = ListStreamsLimitExceededException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable)

