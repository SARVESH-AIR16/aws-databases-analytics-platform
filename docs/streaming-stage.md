# Module 7 stage guide — Kinesis and Firehose

## Data flow

Synthetic order-status events -> Amazon Kinesis Data Streams -> Amazon Data Firehose -> Module 6 analytics S3 bucket.

Firehose writes GZIP-compressed objects beneath `data/streaming/year=YYYY/month=MM/day=DD/`. Delivery errors are written beneath `data/streaming-errors/<error-type>/...`. These are time-based prefixes, not claims that the objects are Parquet; current records are JSON/NDJSON inside GZIP objects.

## Dependencies and switches

- `enable_kinesis_stream=false` by default.
- `enable_firehose_delivery=false` by default.
- Firehose requires both Kinesis and `enable_analytics_stack=true` because it uses the analytics bucket.
- One provisioned shard and minimum 24-hour retention are the defaults.

## Local checks

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-streaming-config.py
python3 scripts/streaming_demo.py validate-sample
python3 scripts/streaming_demo.py simulate
```

All local commands avoid AWS APIs. The demo does not prove Kinesis writes, Firehose delivery, buffering behavior, or S3 object format.

## Temporary AWS demo checklist

1. Verify the intended AWS identity and region; review current Kinesis, Firehose, KMS, S3 and CloudWatch costs for `ap-south-1`.
2. Set the analytics, Kinesis, and Firehose switches deliberately and inspect the full plan. Ask for explicit approval before apply.
3. Create the Kinesis stream and Firehose only for a short demo. Put a handful of synthetic events into the stream only after Firehose is active; allow for the configured buffer interval.
4. Verify the delivery stream status and inspect only the expected success/error prefixes in S3. Keep genuine evidence without exposing credentials or account-sensitive material.
5. Run a destroy plan, review it, then destroy using the same directory, workspace, profile, and Terraform state. Keep the state private until cleanup is independently verified.
6. Inspect for leftover streams, delivery streams, S3 object versions, KMS artifacts, logs, and other resources outside the state. S3 prefixes have a seven-day lifecycle, but do not wait for lifecycle expiry instead of cleaning up.
7. Update README status only to match tests actually completed; include the GitHub link and authentic evidence in the final LinkedIn post.
