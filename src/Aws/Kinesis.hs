{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module: Aws.Kinesis
-- Copyright: Copyright © 2014 AlephCloud Systems, Inc.
-- License: MIT
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- /API Version: 2013-12-02/
--
-- <http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference>
--
-- The types and functions of this package are supposed to be
-- use with the machinery from the
-- <https://hackage.haskell.org/package/aws aws package>.
--
-- Here is a very simple example for making a single request to AWS Kinesis.
--
-- > import Aws
-- > import Aws.Core
-- > import Aws.General
-- > import Aws.Kinesis
-- > import Data.IORef
-- >
-- > cfg <- Aws.baseConfiguration
-- > creds <- Credentials "access-key-id" "secret-access-key" `fmap` newIORef []
-- > let kinesisCfg = KinesisConfiguration UsWest2
-- > simpleAws cfg kinesisCfg $ ListStreams Nothing Nothing
--
-- In order to run the example you must replace @"access-key-id"@ and
-- @"secret-access-key"@ with the respective values for your AWS account.
--
module Aws.Kinesis
( module Aws.Kinesis.Core
, module Aws.Kinesis.Types
, module Aws.Kinesis.Commands.CreateStream
, module Aws.Kinesis.Commands.DeleteStream
, module Aws.Kinesis.Commands.DescribeStream
, module Aws.Kinesis.Commands.GetRecords
, module Aws.Kinesis.Commands.GetShardIterator
, module Aws.Kinesis.Commands.ListStreams
, module Aws.Kinesis.Commands.MergeShards
, module Aws.Kinesis.Commands.PutRecord
, module Aws.Kinesis.Commands.SplitShard
) where

import Aws.Kinesis.Core
import Aws.Kinesis.Types
import Aws.Kinesis.Commands.CreateStream
import Aws.Kinesis.Commands.DeleteStream
import Aws.Kinesis.Commands.DescribeStream
import Aws.Kinesis.Commands.GetRecords
import Aws.Kinesis.Commands.GetShardIterator
import Aws.Kinesis.Commands.ListStreams
import Aws.Kinesis.Commands.MergeShards
import Aws.Kinesis.Commands.PutRecord
import Aws.Kinesis.Commands.SplitShard
