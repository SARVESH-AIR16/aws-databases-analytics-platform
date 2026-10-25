# Module 08 — Database migration with AWS DMS

## Goal

Demonstrate a controlled full-load export of a private PostgreSQL `public.orders` table to the analytics data lake in Parquet format using AWS Database Migration Service (DMS).

## Components

- Private DMS replication instance in the two application private subnets.
- Private PostgreSQL source endpoint using SSL (`ssl_mode = require`).
- S3 Parquet target endpoint writing only under `data/dms-migration/`.
- DMS service roles, an S3 target role limited to the migration prefix, and a security group with PostgreSQL/S3 gateway egress only.
- A full-load task selecting only `public.orders`; task start is separately gated.
- Synthetic source schema and offline validation/dry-run scripts.

## Switches and prerequisites

Everything is opt-in:

- `enable_dms_stack = false` by default.
- `enable_dms_task_start = false` by default.
- DMS requires `enable_rds_stack = true` and `enable_analytics_stack = true`.
- This source endpoint uses explicit PostgreSQL credentials. Enabling the DMS stack requires `rds_manage_master_user_password = false` and a strong `rds_master_password` supplied through `TF_VAR_rds_master_password` or an untracked `.tfvars` file.
- AWS DMS expects account-level service roles named `dms-vpc-role` and `dms-cloudwatch-logs-role`. Check whether they already exist before deployment; import existing roles into Terraform state rather than creating duplicates.
- Confirm the chosen DMS class is available in `ap-south-1` and review current regional pricing before enabling.

**Terraform state warning:** the DMS endpoint provider stores the endpoint password in raw Terraform state. Keep state private, encrypted, access-controlled, and out of GitHub. Never commit `.tfstate`, plans, `.tfvars`, or secrets.

## Local validation

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-dms-config.py
python3 scripts/dms_demo.py validate-sample
python3 scripts/dms_demo.py simulate
```

No local test calls AWS. The offline demo is not proof of a real PostgreSQL connection, DMS endpoint test, migration, or Parquet output.

## Temporary AWS demo checklist

1. Review current DMS replication-instance, RDS, S3, Secrets Manager (if used elsewhere), CloudWatch, data-transfer, and storage pricing for `ap-south-1`.
2. Verify `ghost-hunter-cli` identity and that the required DMS service roles don't already exist, or import them into the current state before apply.
3. Deliberately enable RDS, analytics, and DMS with a protected manual password. Inspect the complete plan and obtain explicit approval before applying.
4. Create the table and synthetic rows using `data/migration/orders-schema.sql` through a secure connection to the private RDS instance. Confirm the private networking path first.
5. Test both DMS endpoint connections. Keep `enable_dms_task_start=false` until tests succeed. Start the full-load task only with explicit approval after that.
6. Verify task status and row counts in the S3 Parquet output. Capture genuine evidence without exposing credentials or account-sensitive data.
7. Run a destroy plan and review it. Destroy resources using the same directory, workspace, profile and state; keep state private until cleanup is independently verified.
8. Audit leftover DMS tasks/endpoints/replication instances, IAM roles and attachments, S3 objects and object versions, CloudWatch logs and any resources outside Terraform state. The migration prefix has a seven-day lifecycle as a backup cleanup aid, not a replacement for explicit deletion.

## Current status

Terraform configuration, static guardrails, sample SQL, synthetic-data validation, and offline dry-run are local only. DMS and all related AWS stacks remain disabled and have not been deployed.
