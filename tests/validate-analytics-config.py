#!/usr/bin/env python3
"""Static guardrails for optional Module 6 resources, plus offline sample test."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
variables = (ROOT / "infrastructure" / "analytics-variables.tf").read_text(encoding="utf-8")
stack = (ROOT / "infrastructure" / "analytics-stack.tf").read_text(encoding="utf-8")
iam = (ROOT / "infrastructure" / "analytics-iam.tf").read_text(encoding="utf-8")
redshift = (ROOT / "infrastructure" / "analytics-redshift.tf").read_text(encoding="utf-8")
outputs = (ROOT / "infrastructure" / "analytics-outputs.tf").read_text(encoding="utf-8")
gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
catalog_statement = iam.split('sid    = "CatalogDiscoveryAndTableMetadata"', 1)[1].split('\n  statement {', 1)[0]
checks = {
    "Analytics stack disabled by default": 'variable "enable_analytics_stack"' in variables and 'default     = false' in variables.split('variable "enable_analytics_stack"', 1)[1].split('\n}', 1)[0],
    "Glue crawler disabled by default and requires analytics stack": 'variable "enable_glue_crawler"' in variables and 'default     = false' in variables.split('variable "enable_glue_crawler"', 1)[1].split('\n}', 1)[0] and 'requires enable_analytics_stack=true' in variables,
    "Redshift stack disabled by default and requires analytics stack": 'variable "enable_redshift_stack"' in variables and 'default     = false' in variables.split('variable "enable_redshift_stack"', 1)[1].split('\n}', 1)[0] and 'requires enable_analytics_stack=true' in variables,
    "S3 data-lake bucket blocks public access": all(bit in stack for bit in ['block_public_acls       = true', 'block_public_policy     = true', 'ignore_public_acls      = true', 'restrict_public_buckets = true']),
    "S3 data-lake uses SSE-S3 and bucket-owner-enforced ownership": 'sse_algorithm = "AES256"' in stack and 'object_ownership = "BucketOwnerEnforced"' in stack,
    "Bucket policy denies insecure transport": 'variable = "aws:SecureTransport"' in stack and 'values   = ["false"]' in stack,
    "Athena results are encrypted and workgroup config is enforced": 'enforce_workgroup_configuration    = true' in stack and 'output_location = "s3://${aws_s3_bucket.analytics_lake[0].bucket}/athena-results/"' in stack and 'encryption_option = "SSE_S3"' in stack,
    "Athena per-query scanned-byte cutoff is configured": 'bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff_bytes' in stack,
    "Glue Catalog database is part of the optional stack": 'resource "aws_glue_catalog_database" "analytics"' in stack and 'name         = "dba_analytics_lake"' in stack,
    "Glue crawler targets only the Parquet prefix": 'resource "aws_glue_crawler" "parquet"' in iam and 's3://${aws_s3_bucket.analytics_lake[0].bucket}/data/parquet/' in iam,
    "Crawler S3 permissions are scoped to the data prefix": 'data/parquet/*' in iam and 's3:PutObject' not in iam,
    "Redshift disabled by default, encrypted, and private": (
        'default     = false' in variables.split('variable "enable_redshift_stack"', 1)[1].split('\n}', 1)[0]
        and 'requires enable_analytics_stack=true' in variables
        and re.search(r'^\s*manage_master_password\s*=\s*true\s*$', redshift, re.MULTILINE)
        and re.search(r'^\s*publicly_accessible\s*=\s*false\s*$', redshift, re.MULTILINE)
        and re.search(r'^\s*encrypted\s*=\s*true\s*$', redshift, re.MULTILINE)
    ),
    "Redshift Spectrum role reads only the Parquet objects": 'data/parquet/*' in redshift and 's3:PutObject' not in redshift,
    "Redshift S3 bucket listing is restricted to the Parquet prefix": 'sid       = "ListLakeParquetPrefix"' in redshift and 'variable = "s3:prefix"' in redshift and 'values   = ["data/parquet", "data/parquet/*"]' in redshift,
    "Glue Catalog metadata permissions are scoped to this analytics database": 'arn:${data.aws_partition.analytics[0].partition}:glue:' in catalog_statement and 'database/${aws_glue_catalog_database.analytics[0].name}' in catalog_statement and 'table/${aws_glue_catalog_database.analytics[0].name}/*' in catalog_statement and 'resources = ["*"]' not in catalog_statement,
    "Redshift security group has no public CIDR ingress": 'aws_vpc_security_group_ingress_rule' in redshift and '0.0.0.0/0' not in redshift,
    "Optional outputs tolerate disabled stacks": 'try(aws_s3_bucket.analytics_lake[0].bucket, null)' in outputs and 'try(aws_redshift_cluster.analytics[0].endpoint, null)' in outputs,
    "Generated local Parquet files are excluded from Git": 'data/analytics/generated/' in gitignore,
}
failed = False
for label, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {label}")
    failed |= not passed
if failed:
    sys.exit(1)

run = subprocess.run(
    [sys.executable, str(ROOT / "scripts" / "analytics_demo.py"), "validate-sample"],
    check=False,
    capture_output=True,
    text=True,
)
print(run.stdout, end="")
if run.returncode:
    print(run.stderr, file=sys.stderr, end="")
    sys.exit(run.returncode)
print("PASS: analytics configuration static guardrails passed.")
