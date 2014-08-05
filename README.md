[![Build Status](https://travis-ci.org/alephcloud/hs-aws-general.svg?branch=master)](https://travis-ci.org/alephcloud/hs-aws-kinesis)


Haskell Bindings for Amazon AWS Kinesis
=======================================

*API Version 2013-12-02*

[Amazon AWS Kinesis API Reference](http://docs.aws.amazon.com/kinesis/2013-12-02/APIReference)

This package depends on the [aws-general](https://github.com/alephcloud/hs-aws-general) package
and the [aws](https://github.com/aristidb/aws) package. From the latter the it borrows the
machinery for [managing AWS credentials](https://hackage.haskell.org/package/aws-0.9/docs/Aws.html#g:17)
and [making requests](https://hackage.haskell.org/package/aws-0.9/docs/Aws.html). There
is also some documentation, including an usage example, in the
[README of the aws package](https://github.com/aristidb/aws/blob/master/README.org)


Installation
============

Assuming that the Haskell compiler *GHC* and the Haskell build tool *cabal* is already
installed run the following command from the shell:

~~~{.sh}
cabal install --enable-tests
~~~

Running Tests
=============

There are few test cases included in the package. These tests require an AWS account
and AWS credentials stored in the file `~/.aws-keys` in the format described in the
[documentation of the aws package](https://hackage.haskell.org/package/aws-0.9/docs/Aws.html#g:17).

When running these tests some (low) costs may incur for usage of the AWS services.
Therefor the user must explicitly consent to the usage of the AWS credentials by
passing the commandline options `--run-with-aws-credentials` to the test application.

~~~{.sh}
cabal test --test-option=--run-with-aws-credentials
~~~

Example Usage
=============

Here is a very simple example for making a single request to AWS Kinesis. For more ellaborate
usage refer to the [documentation of the AWS package](https://hackage.haskell.org/package/aws).

~~~{.haskell}
import Aws
import Aws.Core
import Aws.General
import Aws.Kinesis
import Data.IORef

cfg <- Aws.baseConfiguration
creds <- Credentials "access-key-id" "secret-access-key" `fmap` newIORef []
let kinesisCfg = KinesisConfiguration UsWest2
simpleAws cfg kinesisCfg $ ListStreams Nothing Nothing
~~~

In order to run the example you must replace `"access-key-id"` and
`"secret-access-key"` with the respective values for your AWS account.

You may also take a look at the test examples in
[tests/Main.hs](https://github.com/alephcloud/hs-aws-kinesis/blob/master/tests/Main.hs).

