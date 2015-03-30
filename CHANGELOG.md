0.1.5
=====

*   Provide `NFData` instances for all suitable types.

0.1.4
=====

*   Solve [issue #15](https://github.com/alephcloud/hs-aws-kinesis/issues/15),
    adding support for custom endpoints.

*   Add support for specifying a protocol to `KinesisConfiguration`.

*   Raise lower bound on aws-general to 0.2.1.

0.1.3
=====

*   Fix [bug #9](https://github.com/alephcloud/hs-aws-kinesis/issues/9);
    accept both `Message` and `message` in JSON error responses
    from AWS.

*   Solve [issue #11](https://github.com/alephcloud/hs-aws-kinesis/issues/11);
    export PutRecords from Aws.Kinesis

*   Raise lower bound on aws-general to 0.2.

0.1.2
=====

*   Add support `PutRecords` action.

*   Fix a bug in the `GetShardIterator` action's `ToJSON` instance which
    prevented starting an iterator at a sequence number.

0.1.1
=====

*   Add `IteratedTransaction` and `ListResponse` instances for
    `DescribeStream`, `GetRecords`, and `ListStreams`.

*   Fix recognition of test failures.

0.1
===

First public version.
