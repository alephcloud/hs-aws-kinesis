-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Main
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
-- Module: Main
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- Tests for Haskell Kinesis bindings

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}

module Main
( main
) where

import Aws
import Aws.Kinesis

import Control.Error
import Control.Monad
import Control.Monad.IO.Class

import qualified Data.ByteString as B
import qualified Data.List as L
import Data.Monoid as Monoid
import Data.Proxy
import qualified Data.Text as T

import Test.Tasty

import System.Exit
import System.Environment

import Utils

defaultStreamName :: StreamName
defaultStreamName = "test-stream"

-- -------------------------------------------------------------------------- --
-- Main

-- | Since these tests generate costs there should be a warning and
-- we also should require an explicit command line argument that expresses
-- the concent of the user.
--
main :: IO ()
main = getArgs >>= runMain
  where
    runMain args
        | "--help" `elem` args || "-h" `elem` args = defaultMain tests
        | "--run-with-aws-credentials" `elem` args =
            withArgs (filter (/= "--run-with-aws-credentials") args) $ defaultMain tests
        | otherwise = putStrLn help >> exitFailure

help :: String
help = L.intercalate "\n"
    [ ""
    , "NOTE"
    , ""
    , "This test suite accesses the AWS account that is associated with"
    , "the default credentials from the credential file ~/.aws-keys."
    , ""
    , "By running the tests in this test-suite costs for usage of AWS"
    , "services may incur."
    , ""
    , "In order to actually excute the tests in this test-suite you must"
    , "provide the command line option:"
    , ""
    , "    --run-with-aws-credentials"
    , ""
    , "When running this test-suite through cabal you may use the following"
    , "command:"
    , ""
    , "    cabal test kinesis-tests --test-option=--run-with-aws-credentials"
    , ""
    ]

tests :: TestTree
tests = testGroup "Kinesis Tests"
    [ test_jsonRoundtrips
    , test_createStream
    , test_stream1
    ]

-- -------------------------------------------------------------------------- --
-- Kinesis Utils

kinesisConfiguration :: KinesisConfiguration qt
kinesisConfiguration = defaultKinesisConfiguration testRegion

simpleKinesis
    :: (AsMemoryResponse a, Transaction r a, ServiceConfiguration r ~ KinesisConfiguration, MonadIO m)
    => r
    -> m (MemoryResponse a)
simpleKinesis command = do
    c <- baseConfiguration
    simpleAws c kinesisConfiguration command

simpleKinesisT
    :: (AsMemoryResponse a, Transaction r a, ServiceConfiguration r ~ KinesisConfiguration, MonadIO m)
    => r
    -> ExceptT T.Text m (MemoryResponse a)
simpleKinesisT = tryT . simpleKinesis

testStreamName :: StreamName -> StreamName
testStreamName = either (error . T.unpack) id
        . streamName . T.take 128 . testData . streamNameText

-- | The function 'withResource' from "Tasty" synchronizes the aquired
-- resource through a 'TVar'. We don't need that for a stream. So instead
-- of passing the 'IO StreamName' from 'withResource' we directly pass
-- 'StreamName' to the inner function.
--
withStreamTest
    :: StreamName -- ^ stream name suffix
    -> Int -- ^ shard count
    -> (StreamName -> TestTree)
    -> TestTree
withStreamTest stream shardCount f = withResource createStream deleteStream
    $ const (f tstream)
  where
    createStream = do
        void . simpleKinesis $ CreateStream shardCount tstream
        return tstream
    deleteStream = const . void . simpleKinesis $ DeleteStream tstream
    tstream = testStreamName stream


-- | Wait for a stream to become active
--
waitActiveT
    :: Int
    -- ^ upper bound on the number of seconds to wait.
    -- The actual maximal number of seconds is closest smaller
    -- power of two.
    -> StreamName
    -> ExceptT T.Text IO StreamDescription
waitActiveT sec stream = retryT maxRetry $ do
    DescribeStreamResponse d <- simpleKinesisT
        $ DescribeStream Nothing Nothing stream
    unless (streamDescriptionStreamStatus d == StreamStatusActive)
        $ throwE "Stream is not active"
    return d
  where
    maxRetry = floor $ logBase 2 (fromIntegral sec :: Double)

-- -------------------------------------------------------------------------- --
-- Types

test_jsonRoundtrips :: TestTree
test_jsonRoundtrips = testGroup "JSON encoding roundtrips"
    [ test_jsonRoundtrip (Proxy :: Proxy StreamName)
    , test_jsonRoundtrip (Proxy :: Proxy ShardId)
    , test_jsonRoundtrip (Proxy :: Proxy SequenceNumber)
    , test_jsonRoundtrip (Proxy :: Proxy PartitionHash)
    , test_jsonRoundtrip (Proxy :: Proxy PartitionKey)
    , test_jsonRoundtrip (Proxy :: Proxy ShardIterator)
    , test_jsonRoundtrip (Proxy :: Proxy ShardIteratorType)
    , test_jsonRoundtrip (Proxy :: Proxy Record)
    , test_jsonRoundtrip (Proxy :: Proxy StreamDescription)
    , test_jsonRoundtrip (Proxy :: Proxy StreamStatus)
    , test_jsonRoundtrip (Proxy :: Proxy Shard)
    ]

-- -------------------------------------------------------------------------- --
-- Stream Tests

test_stream1 :: TestTree
test_stream1 = withStreamTest defaultStreamName 1 $ \stream ->
    testGroup "Perform a series of tests on a single stream"
        [ exceptTOnceTest0 "list streams" (prop_streamList stream)
        , exceptTOnceTest0 "describe stream" (prop_streamDescribe 1 stream)
        , exceptTOnceTest2 "put and get stream" (prop_streamPutGet stream)
        ]

prop_streamList :: StreamName -> ExceptT T.Text IO ()
prop_streamList stream = do
    ListStreamsResponse _ streams <- simpleKinesisT $ ListStreams Nothing Nothing
    unless (stream `elem` streams) $
        throwE $ "stream " Monoid.<> streamNameText stream <> " is not listed"

prop_streamDescribe
    :: Int -- ^  expected number of shards
    -> StreamName
    -> ExceptT T.Text IO ()
prop_streamDescribe shardNum stream = do
    desc <- waitActiveT 64 stream

    unless (streamDescriptionStreamName desc == stream)
        . throwE $ "unexpected stream name in description: "
        <> streamNameText (streamDescriptionStreamName desc)

    let l = length $ streamDescriptionShards desc
    unless (l == shardNum)
        . throwE $ "unexpected number of shards in stream description: " <> sshow l

prop_streamPutGet
    :: StreamName
    -> B.ByteString -- ^ Message data
    -> PartitionKey
    -> ExceptT T.Text IO ()
prop_streamPutGet stream dat key = do
    desc <- waitActiveT 64 stream

    let shards = streamDescriptionShards desc

    PutRecordResponse putSeqNr putShard <- simpleKinesisT PutRecord
        { putRecordData = dat
        , putRecordExplicitHashKey = Nothing
        , putRecordPartitionKey = key
        , putRecordSequenceNumberForOrdering = Nothing
        , putRecordStreamName = stream
        }

    let shardIds = map shardShardId shards
    unless (putShard `elem` shardIds) . throwE
        $ "unexpected shard id: expected on of " <> sshow shardIds <> "; got " <> sshow putShard

    record <- retryT 5 $ do
        GetShardIteratorResponse it <- simpleKinesisT GetShardIterator
            { getShardIteratorShardId = putShard
            , getShardIteratorShardIteratorType = TrimHorizon
            , getShardIteratorStartingSequenceNumber = Nothing
            , getShardIteratorStreamName = stream
            }
        GetRecordsResponse _nextIt records <- simpleKinesisT GetRecords
            { getRecordsLimit = Nothing
            , getRecordsShardIterator = it
            }
        case records of
            [] -> throwE "no record found in stream"
            [r] -> return r
            t -> throwE $ "unexpected records found in stream: " <> sshow t

    let getData = recordData record
    unless (getData == dat) . throwE
        $ "data does not match: expected " <> sshow dat <> "; got " <> sshow getData

    let getSeqNr = recordSequenceNumber record
    unless (getSeqNr == putSeqNr) . throwE
        $ "sequence numbers don't match: expected " <> sshow putSeqNr
        <> "; got " <> sshow getSeqNr

    let getPartKey = recordPartitionKey record
    unless (getPartKey == key) . throwE
        $ "partition keys don't match: expected " <> sshow key
        <> "; got " <> sshow getPartKey

-- -------------------------------------------------------------------------- --
-- Stream Creation Tests

test_createStream :: TestTree
test_createStream = testGroup "Stream creation"
    [ exceptTOnceTest1 "create list delete" prop_createListDelete
    ]

prop_createListDelete
    :: StreamName -- ^ stream name
    -> ExceptT T.Text IO ()
prop_createListDelete stream = do
    CreateStreamResponse <- simpleKinesisT $ CreateStream 1 tstream
    flip catchE (\e -> deleteStream >> throwE e) $ do
       ListStreamsResponse _ allStreams <- simpleKinesisT
           $ ListStreams Nothing Nothing
       unless (tstream `elem` allStreams)
           . throwE $ "stream " <> streamNameText tstream <> " not listed"
       deleteStream
  where
    deleteStream = void $ simpleKinesisT (DeleteStream tstream)
    tstream = testStreamName stream

