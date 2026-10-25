#!/usr/bin/env python3
"""Static safety checks for Module 7; no AWS APIs are called."""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
INFRA = ROOT / "infrastructure"

def read(rel: str) -> str:
    path = ROOT / rel
    if not path.is_file():
        raise AssertionError(f"Missing required file: {rel}")
    return path.read_text(encoding="utf-8")

def require(label: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(label)
    print(f"PASS: {label}")

def main() -> int:
    variables = read("infrastructure/streaming-variables.tf")
    stream = read("infrastructure/streaming-stack.tf")
    iam = read("infrastructure/streaming-iam.tf")
    firehose = read("infrastructure/streaming-firehose.tf")
    outputs = read("infrastructure/streaming-outputs.tf")
    analytics_stack = read("infrastructure/analytics-stack.tf")

    require("Kinesis stream disabled by default", 'variable "enable_kinesis_stream"' in variables and 'default     = false' in variables.split('variable "enable_kinesis_stream"', 1)[1].split("}", 1)[0])
    firehose_var = variables.split('variable "enable_firehose_delivery"', 1)[1].split('variable "firehose_buffering_size_mb"', 1)[0]
    require("Firehose disabled by default", 'default     = false' in firehose_var)
    require("Firehose requires both Kinesis and analytics stacks", "var.enable_kinesis_stream" in firehose_var and "var.enable_analytics_stack" in firehose_var)
    require("Kinesis stream count is guarded by opt-in", 'count = var.enable_kinesis_stream ? 1 : 0' in stream)
    require("Provisioned stream defaults to one shard and 24-hour retention", 'default     = 1' in variables.split('variable "kinesis_shard_count"', 1)[1].split("}", 1)[0] and 'default     = 24' in variables.split('variable "kinesis_retention_hours"', 1)[1].split("}", 1)[0])
    require("Kinesis encryption at rest uses KMS", 'encryption_type  = "KMS"' in stream and 'kms_key_id       = "alias/aws/kinesis"' in stream)
    require("Producer policy grants stream record writes and scoped KMS data-key generation", '"kinesis:PutRecord"' in stream and '"kinesis:PutRecords"' in stream and '"kms:GenerateDataKey"' in stream and 'variable = "kms:ViaService"' in stream and 'variable = "kms:EncryptionContext:aws:kinesis:arn"' in stream and '"kinesis:*"' not in stream)
    require("Firehose resource is opt-in and delivers to S3", 'count = var.enable_firehose_delivery ? 1 : 0' in firehose and 'destination = "extended_s3"' in firehose and "aws_s3_bucket.analytics_lake[0].arn" in firehose)
    require("Firehose uses GZIP and date-partitioned success/error prefixes", 'compression_format = "GZIP"' in firehose and 'data/streaming/year=' in firehose and 'data/streaming-errors/!{firehose:error-output-type}' in firehose)
    require("Firehose buffering is bounded by validated variables", "var.firehose_buffering_size_mb" in firehose and "var.firehose_buffering_interval_seconds" in firehose and "buffering_interval_seconds must be a whole number from 60 through 900" in variables)
    require("Firehose trust is restricted to source account and exact stream ARN", 'variable = "aws:SourceAccount"' in iam and 'variable = "aws:SourceArn"' in iam and "deliverystream/db-analytics-orders-firehose" in iam)
    require("Kinesis read permissions are scoped to the configured stream ARN", 'resources = [aws_kinesis_stream.orders[0].arn]' in iam and '"kinesis:*"' not in iam)
    require("KMS decrypt is restricted by Kinesis service and stream encryption context", '"kms:Decrypt"' in iam and 'variable = "kms:ViaService"' in iam and 'variable = "kms:EncryptionContext:aws:kinesis:arn"' in iam)
    require("S3 bucket listing is constrained to streaming prefixes", 'variable = "s3:prefix"' in iam and '"data/streaming/*"' in iam and '"data/streaming-errors/*"' in iam)
    bucket_location_split = iam.split('"GetAnalyticsBucketLocation"', 1)
    bucket_location_policy = bucket_location_split[1].split("\n  statement {", 1)[0] if len(bucket_location_split) == 2 else ""
    require(
        "S3 bucket-location permission is not blocked by the prefix condition",
        '"s3:GetBucketLocation"' in bucket_location_policy
        and "aws_s3_bucket.analytics_lake[0].arn" in bucket_location_policy
        and "condition {" not in bucket_location_policy,
    )
    require("S3 object writes are limited to streaming and error prefixes", '"${aws_s3_bucket.analytics_lake[0].arn}/data/streaming/*"' in iam and '"${aws_s3_bucket.analytics_lake[0].arn}/data/streaming-errors/*"' in iam and '"s3:*"' not in iam)
    require("S3 lifecycle expires streaming outputs and errors after seven days", 'id     = "expire-streaming-data"' in analytics_stack and 'id     = "expire-streaming-error-data"' in analytics_stack)
    require("Optional outputs safely return null when stacks are disabled", "try(aws_kinesis_stream.orders[0].name, null)" in outputs and "try(aws_kinesis_firehose_delivery_stream.orders_to_s3[0].arn, null)" in outputs)
    require("No public ingress or VPC access rule was added for managed Kinesis services", not (ROOT / "infrastructure" / "streaming-security-groups.tf").exists())
    print("PASS: streaming configuration static guardrails passed.")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
