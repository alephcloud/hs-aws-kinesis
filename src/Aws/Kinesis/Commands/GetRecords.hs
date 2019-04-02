-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Aws.Kinesis.Commands.GetRecords
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
-- Module: Aws.Kinesis.Commands.GetRecords
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- This operation returns one or more data records from a shard. A GetRecords
-- operation request can retrieve up to 10 MB of data.
--
-- You specify a shard iterator for the shard that you want to read data from
-- in the ShardIterator parameter. The shard iterator specifies the position in
-- the shard from which you want to start reading data records sequentially. A
-- shard iterator specifies this position using the sequence number of a data
-- record in the shard. For more information about the shard iterator, see
-- GetShardIterator.
--
-- GetRecords may return a partial result if the response size limit is
-- exceeded. You will get an error, but not a partial result if the shard's
-- provisioned throughput is exceeded, the shard iterator has expired, or an
-- internal processing failure has occurred. Clients can request a smaller
-- amount of data by specifying a maximum number of returned records using the
-- Limit parameter. The Limit parameter can be set to an integer value of up to
-- 10,000. If you set the value to an integer greater than 10,000, you will
-- receive InvalidArgumentException.
--
-- A new shard iterator is returned by every GetRecords request in
-- NextShardIterator, which you use in the ShardIterator parameter of the next
-- GetRecords request. When you repeatedly read from an Amazon Kinesis stream
-- use a GetShardIterator request to get the first shard iterator to use in
-- your first GetRecords request and then use the shard iterator returned in
-- NextShardIterator for subsequent reads.
--
-- GetRecords can return null for the NextShardIterator to reflect that the
-- shard has been closed and that the requested shard iterator would never have
-- returned more data.
--
-- If no items can be processed because of insufficient provisioned throughput
-- on the shard involved in the request, GetRecords throws
-- ProvisionedThroughputExceededException.
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference/API_GetRecords.html>

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Aws.Kinesis.Commands.GetRecords
( GetRecords(..)
, GetRecordsResponse(..)
, GetRecordsExceptions(..)
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
import Data.Typeable

import GHC.Generics

getRecordsAction :: KinesisAction
getRecordsAction = KinesisGetRecords

data GetRecords = GetRecords
    { getRecordsLimit :: !(Maybe Int)
    -- ^ The maximum number of records to return, which can be set to a value
    -- of up to 10,000.

    , getRecordsShardIterator :: !ShardIterator
    -- ^ The position in the shard from which you want to start sequentially
    -- reading data records.
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData GetRecords

instance ToJSON GetRecords where
    toJSON GetRecords{..} = object
        [ "Limit" .= getRecordsLimit
        , "ShardIterator" .= getRecordsShardIterator
        ]

data GetRecordsResponse = GetRecordsResponse
    { getRecordsResNextShardIterator :: !(Maybe ShardIterator)
    -- ^ The next position in the shard from which to start sequentially
    -- reading data records. If set to null, the shard has been closed and the
    -- requested iterator will not return any more data.

    , getRecordsResRecords :: ![Record]
    -- ^ List of Records
    }
    deriving (Show, Read, Eq, Ord, Typeable, Generic)

instance NFData GetRecordsResponse

instance FromJSON GetRecordsResponse where
    parseJSON = withObject "GetRecordsResponse" $ \o -> GetRecordsResponse
        <$> o .:? "NextShardIterator" .!= Nothing
        <*> o .: "Records"

instance ResponseConsumer r GetRecordsResponse where
    type ResponseMetadata GetRecordsResponse = KinesisMetadata
#if MIN_VERSION_aws(0,15,0)
    responseConsumer _ _ = kinesisResponseConsumer
#else
    responseConsumer _ = kinesisResponseConsumer
#endif

instance SignQuery GetRecords where
    type ServiceConfiguration GetRecords = KinesisConfiguration
    signQuery cmd = kinesisSignQuery KinesisQuery
        { kinesisQueryAction = getRecordsAction
        , kinesisQueryBody = Just $ LB.toStrict $ encode cmd
        }

instance Transaction GetRecords GetRecordsResponse

instance AsMemoryResponse GetRecordsResponse where
    type MemoryResponse GetRecordsResponse = GetRecordsResponse
    loadToMemory = return

instance ListResponse GetRecordsResponse Record where
    listResponse (GetRecordsResponse _ records) = records

-- | The request parameter 'getRecordsLimit' is interpreted as limit for each
-- single request and not for the overall transaction.
--
instance IteratedTransaction GetRecords GetRecordsResponse where
    nextIteratedRequest GetRecords{..} GetRecordsResponse{..} =
        GetRecords getRecordsLimit <$> getRecordsResNextShardIterator

-- -------------------------------------------------------------------------- --
-- Exceptions
--
-- Currently not used for requests. It's included for future usage
-- and as reference.

data GetRecordsExceptions
    = GetRecordsExpiredIteratorException
    -- ^ /Code 400/

    | GetRecordsInvalidArgumentException
    -- ^ /Code 400/

    | GetRecordsProvisionedThroughputExceededException
    -- ^ /Code 400/

    | GetRecordsResourceNotFoundException
    -- ^ /Code 400/

    deriving (Show, Read, Eq, Ord, Enum, Bounded, Typeable, Generic)

instance NFData GetRecordsExceptions


