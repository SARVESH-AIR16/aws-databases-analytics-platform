# Module 06 — Analytics foundations

## Scope

- Private-by-default S3 data lake for Parquet order records.
- Server-side encryption, all public-access blocks, bucket-owner-enforced ownership,
  HTTPS-only bucket policy, versioning and lifecycle cleanup for query results.
- AWS Glue Data Catalog database and an optional on-demand S3 crawler.
- Athena workgroup with enforced encrypted results and a per-query bytes-scanned cutoff.
- Optional private, encrypted, single-node provisioned Redshift cluster with a
  managed administrator password and read-only S3/Glue access for Spectrum.

## Cost and safety defaults

All three switches default to `false`:

- `enable_analytics_stack`
- `enable_glue_crawler`
- `enable_redshift_stack`

The crawler and Redshift cluster require the base analytics stack. Athena costs
are incurred when queries run; Glue crawler runs are billable; S3 storage and
requests may incur charges. A provisioned Redshift cluster incurs ongoing compute
charges for as long as it runs. The S3 bucket uses `force_destroy = true` to make
approved temporary demos removable, so Terraform destroy will delete every object
and object version in that module-owned bucket. Never store personal or important
production data there.

Review current `ap-south-1` prices and quotas before enabling any cloud resources.
Do not apply a plan without explicit deployment approval.

## Local validation

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-analytics-config.py
python3 scripts/analytics_demo.py validate-sample
```

Optional local Parquet generation requires PyArrow and does not call AWS APIs:

```bash
python3 -m pip install pyarrow
python3 scripts/analytics_demo.py build-parquet
```

The output is ignored by Git under `data/analytics/generated/`. Upload it to the
approved S3 prefix only after the analytics stack has been deliberately deployed.
See `docs/analytics-stage.md` and the SQL files under `data/analytics/` for the
crawl/query workflow.

## Current status

Terraform configuration, local static checks, synthetic-data validation and SQL
examples are authored locally. Validation must be run on the repository after
installation. All cloud resources remain undeployed and disabled by default.
