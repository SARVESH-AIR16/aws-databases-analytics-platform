# Module 06 — Analytics stage guide

## Components

The optional analytics stack creates an account-and-region-named S3 data-lake
bucket, Glue Data Catalog database (`dba_analytics_lake`) and an Athena workgroup
(`db-analytics-wg`). The workgroup enforces SSE-S3-encrypted results in the
module bucket and stops individual queries that exceed the configured 50 MiB
scan cutoff by default. Public access is blocked at the bucket, ownership is
bucket-owner enforced, noncurrent versions expire after seven days, and Athena
result objects expire after seven days.

`enable_glue_crawler` adds an on-demand Glue crawler over `data/parquet/`; it is
not scheduled and does not run simply because Terraform creates it. Upload a
Parquet file to a child prefix such as `data/parquet/orders/`, run the crawler,
and inspect the resulting table name in Glue Catalog before running the queries
in `data/analytics/athena-queries.sql`.

`enable_redshift_stack` adds a private single-node provisioned Redshift cluster
in the two analytics private subnets. It uses an AWS-managed Secrets Manager
administrator password, encryption at rest, no public accessibility, enhanced
VPC routing, and a read-only IAM role for the Parquet S3 prefix and Glue Catalog.
Use `data/analytics/redshift-spectrum.sql` after the Glue crawler has populated
metadata. The cluster is not highly available and must be treated as an ephemeral
portfolio demo, not a production warehouse.

## Current switches

All default values are `false` for `enable_analytics_stack`, `enable_glue_crawler`,
and `enable_redshift_stack`. Keep them that way during local validation.

## Price and cleanup warnings

- S3 storage, requests, data transfer and retained objects can be charged.
- Athena charges for data scanned per query; the workgroup cutoff is a guardrail,
  not a global billing cap.
- Glue crawler runtime is billable; run it only for the demo workload.
- Provisioned Redshift is billed while running, plus associated storage and other
  usage. Destroy it after the demo; it does not automatically stop when idle.
- The analytics bucket is deliberately configured for Terraform-managed deletion
  of all its objects and versions. Back up any desired evidence elsewhere first.
- A billing budget or alert is not a hard spending cap. Review live Mumbai-region
  pricing and AWS account quotas before creating resources.

Official pricing references (re-check before deployment):

- [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/)
- [Amazon Athena pricing](https://aws.amazon.com/athena/pricing/)
- [AWS Glue pricing](https://aws.amazon.com/glue/pricing/)
- [Amazon Redshift pricing](https://aws.amazon.com/redshift/pricing/)

## Validation commands

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-analytics-config.py
python3 scripts/analytics_demo.py validate-sample
```

These commands perform local validation only. They do not contact AWS or prove
live service behavior. Any actual deployment requires a fresh plan, separate cost
review and explicit user approval.
