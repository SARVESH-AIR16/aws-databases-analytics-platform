# Module 07 — Streaming and ingestion

## Scope

- Amazon Kinesis Data Streams with one provisioned shard by default, 24-hour retention, and KMS server-side encryption.
- Amazon Data Firehose consumes that Kinesis stream and writes compressed, date-partitioned objects to the Module 6 analytics S3 bucket.
- Separate success and error prefixes, bounded S3 buffering, and a Firehose role scoped to the stream and two destination prefixes.
- A least-privilege producer policy template for `PutRecord`/`PutRecords` plus KMS data-key generation restricted to this stream; it is output for review and is not attached to an IAM identity.
- Synthetic NDJSON validation and an offline stream-to-S3 flow illustration.

## Cost-aware defaults

Both `enable_kinesis_stream` and `enable_firehose_delivery` default to `false`. Firehose delivery also requires `enable_analytics_stack = true`. Provisioned Kinesis shards can incur hourly charges for as long as the stream exists; Firehose charges depend on ingest volume and record sizing. Confirm current Mumbai (`ap-south-1`) prices before enabling anything. A cost review and explicit approval are required before `terraform apply`.

The Firehose destination buffers up to 5 MiB or 300 seconds by default, then compresses objects with GZIP. Buffering affects delivery latency. Streaming and error prefixes are configured to expire after seven days under the analytics S3 bucket's lifecycle rules. These controls reduce retained demo data but are not a spending cap.

## Security

- Kinesis server-side encryption uses the AWS-managed `alias/aws/kinesis` key.
- The Firehose trust policy is restricted to this account and the exact named delivery stream.
- Stream read actions are scoped to the configured stream. Decryption is conditioned on Kinesis as the calling service and the stream ARN encryption context.
- S3 listing is limited to the streaming prefixes; object actions apply only to those prefixes.
- The producer policy is an unattached JSON output and grants only stream metadata, record writes, and KMS data-key generation conditioned on this stream.

## Local validation

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-streaming-config.py
python3 scripts/streaming_demo.py validate-sample
python3 scripts/streaming_demo.py simulate
```

The Python simulation is offline only: it does not send records to Kinesis, invoke Firehose, validate AWS delivery, or measure throughput.

## Current status

Terraform configuration, sample events, local static guardrails, and offline simulation are implemented locally. Neither service has been deployed. Live ingestion and S3 delivery remain pending a fresh plan, current regional cost review, explicit approval, and real-service tests. After a temporary demonstration, destroy resources and independently verify cleanup before publishing evidence.
