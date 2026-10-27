# AWS Databases and Analytics Platform

A Terraform-managed AWS portfolio project covering network segmentation,
relational and NoSQL databases, caching, analytics, streaming, migration,
security controls, automated validation and cost-conscious operations.

## Public repository

[GitHub repository](https://github.com/SARVESH-AIR16/aws-databases-analytics-platform)

## Current implementation status

The temporary demo was deployed, verified and then destroyed. These statuses
describe that historical demo, not resources currently running in AWS.

| Area | Repository/default state | Temporary demo result |
|---|---|---|
| Network foundation | Terraform design for two VPCs and five subnets | Both VPCs were deployed, and VPC peering was active before cleanup. |
| Security groups and VPC endpoints | Defined in Terraform | Project resources were included in the successful teardown. |
| EC2 compute | Optional host configuration | The analytics worker was verified running as `t3.micro` before cleanup. |
| RDS PostgreSQL | Optional stack, disabled by default | `db-analytics-postgres` was available, `db.t4g.micro`, 20 GB storage, private, with one-day backup retention. |
| DynamoDB | Optional orders table | `db-analytics-orders` was `ACTIVE` before cleanup. |
| ElastiCache Valkey | Optional cache stack | The Valkey replication group was available before cleanup. DAX was not deployed. |
| S3 and Glue Data Catalog | Optional analytics configuration | S3 default encryption was AES256; Glue database `dba_analytics_lake` existed before cleanup. |
| Other optional services | Configuration and local validation only | Aurora, RDS Proxy, read replica, DAX, Athena workgroup/crawler, Redshift, Kinesis, Firehose and DMS were not deployed as live services in this demo. |

The Terraform destroy completed with 73 resources destroyed. Subsequent read-only
checks confirmed the project database, Valkey replication group, DynamoDB table,
S3 lake bucket, Glue database, both VPCs and analytics worker were no longer
found. These checks do not prove that the AWS bill is zero; review billing for
delayed charges.

## Locked network address plan

### Application VPC — `10.0.0.0/16`
- Public subnet `10.0.1.0/24`, `ap-south-1a`
- Private subnet A `10.0.2.0/24`, `ap-south-1a`
- Private subnet B `10.0.3.0/24`, `ap-south-1b`

### Analytics VPC — `10.1.0.0/16`
- Private subnet A `10.1.1.0/24`, `ap-south-1a`
- Private subnet B `10.1.2.0/24`, `ap-south-1b`

The design includes VPC peering, tier-specific security groups, S3 gateway
endpoints in each VPC, and a DynamoDB gateway endpoint in the application VPC.
No NAT Gateway is included by default. Subnets do not automatically assign
public IPv4 addresses. See [architecture overview](docs/architecture.md),
[network design](docs/network-design.md), and
[diagram source](docs/architecture-diagram.mmd).

## Eight modules

1. **Relational databases** — RDS PostgreSQL, Aurora PostgreSQL and schema.
2. **Availability and reads** — Multi-AZ and read-replica/reader options.
3. **Database connections** — RDS Proxy, backups and recovery.
4. **DynamoDB** — Orders table, composite key, GSI, least-privilege role and sample operations.
5. **Caching** — ElastiCache for Valkey and DynamoDB Accelerator (DAX).
6. **Analytics foundations** — S3 Parquet data lake, Glue Data Catalog, Athena and optional Redshift.
7. **Streaming and ingestion** — Kinesis Data Streams and Firehose delivery to the analytics S3 lake.
8. **Database migration** — AWS DMS full-load from private PostgreSQL to an S3 Parquet target, with migration validation.

These modules describe the repository's configurable infrastructure and local
validation. They do not imply all services were deployed. Only the services
identified in the temporary-demo status table above were verified live. All
optional AWS service stacks remain disabled by default. Local DMS validation or
simulation does not mean an AWS migration occurred.

## Local validation

Prerequisites: Terraform, AWS CLI, Python 3 and Git.

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 scripts/validate-cidrs.py
python3 tests/validate-relational-config.py
python3 tests/validate-dynamodb-config.py
python3 tests/validate-cache-config.py
python3 tests/validate-analytics-config.py
python3 tests/validate-streaming-config.py
python3 tests/validate-dms-config.py
python3 scripts/dynamodb_demo.py validate-sample
python3 scripts/cache_demo.py validate-sample
python3 scripts/analytics_demo.py validate-sample
python3 scripts/streaming_demo.py validate-sample
python3 scripts/streaming_demo.py simulate
python3 scripts/dms_demo.py validate-sample
python3 scripts/dms_demo.py simulate
```

To create a plan for a future deployment, first configure and verify a
dedicated non-root AWS identity with the permissions required for the services
you explicitly choose to enable. The temporary demo deployment profile has
been removed. Do not assume the existing `ghost-hunter` or `ghost-hunter-cli`
profiles have permissions for this project. Review current AWS pricing and a
fresh Terraform plan before any approved deployment; do not run `apply` without
a separate resource and cost review.

## Security and cost

- Use an appropriately permissioned non-root AWS identity and never commit keys,
  Terraform state, saved plans or secret-bearing variable files.
- RDS/Aurora, RDS Proxy, caches, DAX, Redshift, DMS, streaming, EC2, backups and
  data transfer can incur charges.
- DynamoDB table storage and request units are billable. Its on-demand throughput
  maximum is a best-effort control that may throttle requests, not a strict
  billing cap. PITR and Streams remain off by default.
- The RDS setup is private and encrypted; the RDS Proxy path requires TLS.
  A PostgreSQL read replica requires manually managed credentials in this design;
  Terraform state may then contain sensitive database password values.
- The bastion SSH ingress is disabled until a trusted admin CIDR is configured.
  Never use `0.0.0.0/0` for SSH.
- Gateway endpoints provide network routing, not IAM authorization. Budgets and
  alerts are notifications, not hard spending caps.
- Verify resource cleanup after approved demonstrations.

## Portfolio evidence

The report `docs/evidence/live-demo-verification-2026-10-27.md` records the
temporary demo and cleanup. Six screenshots captured before teardown are in
`docs/screenshots/`. They are historical snapshots; they do not mean that AWS
resources are still running. Portfolio claims must distinguish verified live
services from optional modules that were only configured or locally validated.

## EC2 host layer

The optional compute host layer adds the administration bastion, private application host, and optional private analytics worker. They remain disabled by default until a deployment plan and cost review are approved. See `modules/09-compute-hosts/README.md`.
