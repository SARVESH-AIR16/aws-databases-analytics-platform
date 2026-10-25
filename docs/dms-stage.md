# Module 08 stage — AWS Database Migration Service

## Scope

Optional AWS DMS full-load task: private RDS PostgreSQL `public.orders` to the Module 6 S3 data lake in Parquet under `data/dms-migration/`.

## Cost and safety defaults

- DMS is disabled by default; full-load task start is a separate opt-in.
- DMS requires the optional RDS PostgreSQL and analytics S3 stacks.
- DMS replication instances incur compute-hour charges while provisioned. Choose class/storage only after current `ap-south-1` pricing and availability review.
- The replication instance is private in two application private subnets. Security-group egress is limited to PostgreSQL and the S3 gateway endpoint.
- S3 permissions are restricted to the migration prefix; bucket-location permission is separate from prefix-constrained listing.
- Output objects are scheduled for expiry after seven days. Still explicitly clean data and versions during teardown.
- DMS source endpoint credentials are passed as a sensitive variable but the provider stores endpoint passwords in Terraform state. Never push state to GitHub.
- DMS requires account-level service roles `dms-vpc-role` and `dms-cloudwatch-logs-role`; import pre-existing roles rather than trying to recreate them.

## Local checks

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-dms-config.py
python3 scripts/dms_demo.py validate-sample
python3 scripts/dms_demo.py simulate
```

These checks make no AWS calls and do not prove a live migration. The SQL fixture creates only synthetic orders. Test both endpoints, then start the task explicitly after the prerequisites are satisfied.
