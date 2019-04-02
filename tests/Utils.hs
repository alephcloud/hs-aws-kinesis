-- Copyright (c) 2013-2015 PivotCloud, Inc.
--
-- Utils
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
-- Module: Utils
-- Copyright: Copyright (c) 2013-2015 PivotCloud, Inc.
-- license: Apache License, Version 2.0
-- Maintainer: Lars Kuhtz <lars@alephcloud.com>
-- Stability: experimental
--
-- Utils for Tests for Haskell AWS bindints

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE CPP #-}

module Utils
(
-- * Parameters
  testRegion
, testDataPrefix

-- * General Utils
, sshow
, tryT
, retryT
, testData

, evalTestT
, evalTestTM
, exceptTOnceTest0
, exceptTOnceTest1
, exceptTOnceTest2

-- * Generic Tests
, test_jsonRoundtrip
, prop_jsonRoundtrip
) where

import Aws.General

import Control.Concurrent (threadDelay)
import Control.Error
import Control.Monad
import Control.Monad.Identity
import Control.Monad.IO.Class

import Data.Aeson (FromJSON, ToJSON, encode, eitherDecode)
import Data.Monoid as Monoid
import Data.Proxy
import Data.String
import qualified Data.Text as T
import Data.Typeable

import Test.QuickCheck.Property
import Test.QuickCheck.Monadic
import Test.Tasty
import Test.Tasty.QuickCheck

-- -------------------------------------------------------------------------- --
-- Static Test parameters
--
-- TODO make these configurable

testRegion :: Region
testRegion = UsWest2

-- | This prefix is used for the IDs and names of all entities that are
-- created in the AWS account.
--
testDataPrefix :: IsString a => a
testDataPrefix = "__TEST_AWSHASKELLBINDINGS__"

-- -------------------------------------------------------------------------- --
-- General Utils

tryT :: MonadIO m => IO a -> ExceptT T.Text m a
tryT = fmapLT (T.pack . show) . syncIO

testData :: (IsString a, Monoid a) => a -> a
testData a = testDataPrefix Monoid.<> a

retryT :: MonadIO m => Int -> ExceptT T.Text m a -> ExceptT T.Text m a
retryT i f = go 1
  where
    go x
        | x >= i = fmapLT (\e -> "error after " <> sshow x <> " retries: " <> e) f
        | otherwise = f `catchE` \_ -> do
            liftIO $ threadDelay (1000000 * min 60 (2^(x-1)))
            go (succ x)

sshow :: (Show a, IsString b) => a -> b
sshow = fromString . show

evalTestTM
    :: Functor f
    => String -- ^ test name
    -> f (ExceptT T.Text IO a) -- ^ test
    -> f (PropertyM IO Bool)
evalTestTM name = fmap $
    (liftIO . runExceptT) >=> \r -> case r of
        Left e ->
            fail $ "failed to run test \"" <> name <> "\": " <> show e
        Right _ -> return True

evalTestT
    :: String -- ^ test name
    -> ExceptT T.Text IO a -- ^ test
    -> PropertyM IO Bool
evalTestT name = runIdentity . evalTestTM name . Identity

exceptTOnceTest0
    :: String -- ^ test name
    -> ExceptT T.Text IO a -- ^ test
    -> TestTree
exceptTOnceTest0 name test = testProperty name . once . monadicIO
    $ evalTestT name test

exceptTOnceTest1
    :: (Arbitrary a, Show a)
    => String -- ^ test name
    -> (a -> ExceptT T.Text IO b)
    -> TestTree
exceptTOnceTest1 name test = testProperty name . once $ monadicIO
    . evalTestTM name test

exceptTOnceTest2
    :: (Arbitrary a, Show a, Arbitrary b, Show b)
    => String -- ^ test name
    -> (a -> b -> ExceptT T.Text IO c)
    -> TestTree
exceptTOnceTest2 name test = testProperty name . once $ \a b -> monadicIO
    $ (evalTestTM name $ uncurry test) (a, b)

-- -------------------------------------------------------------------------- --
-- Generic Tests

test_jsonRoundtrip
    :: forall a . (Eq a, Show a, FromJSON a, ToJSON a, Typeable a, Arbitrary a)
    => Proxy a
    -> TestTree
test_jsonRoundtrip proxy = testProperty msg (prop_jsonRoundtrip :: a -> Property)
  where
    msg = "JSON roundtrip for " <> show typ
#if MIN_VERSION_base(4,7,0)
    typ = typeRep proxy
#else
    typ = typeOf (undefined :: a)
#endif

prop_jsonRoundtrip :: forall a . (Eq a, Show a, FromJSON a, ToJSON a) => a -> Property
prop_jsonRoundtrip a = either (const $ property False) (\(b :: [a]) -> [a] === b) $
    eitherDecode $ encode [a]

