# AWS Databases and Analytics Platform

A Terraform-managed AWS portfolio project covering network segmentation,
relational and NoSQL databases, caching, analytics, streaming, migration,
security controls, automated validation and cost-conscious operations.

## Public repository

[GitHub repository](https://github.com/SARVESH-AIR16/aws-databases-analytics-platform)

## Current implementation status

| Area | Status |
|---|---|
| Two-VPC, five-subnet foundation | Local Terraform validation and CIDR checks passed; not deployed |
| Network security groups and gateway endpoints | Terraform validation passed; not deployed |
| RDS/Aurora and RDS Proxy | Optional Terraform code and static guardrails added; disabled and not deployed |
| DynamoDB | Optional table, index, scoped IAM and sample validation; disabled and not deployed |
| Caching | Optional ElastiCache/Valkey and DAX configuration and local guardrails added; disabled and not deployed |
| Analytics foundations | Optional S3, Glue, Athena and Redshift configuration and local checks added; disabled and not deployed |
| Streaming and ingestion | Optional Kinesis and Firehose configuration and local checks added; disabled and not deployed |
| Database migration | Planned; implementation and evidence remain |

A valid Terraform configuration or plan does not prove resources were created or
that services work end-to-end. Keep status aligned with the latest repeatable tests.

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
8. **Database migration** — AWS DMS and migration validation.

Modules 1–7 now contain optional configuration and/or local validation assets. All
AWS service stacks remain disabled by default and have not been deployed. Module 8
still requires implementation, validation and evidence.

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
python3 scripts/dynamodb_demo.py validate-sample
python3 scripts/cache_demo.py validate-sample
python3 scripts/analytics_demo.py validate-sample
python3 scripts/streaming_demo.py validate-sample
python3 scripts/streaming_demo.py simulate
```

To generate an AWS plan after reviewing current pricing and confirming the intended
AWS identity:

```bash
AWS_PROFILE=ghost-hunter-cli AWS_REGION=ap-south-1 \
  terraform -chdir=infrastructure plan
```

Local validators do not call AWS. Review a fresh plan before any deployment; none
of the optional analytics, database, cache, streaming or Redshift stacks are enabled by default.

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

The finished project should include reproducible infrastructure and tests,
synthetic data, architecture evidence, module documentation, a cost/security/
cleanup guide and genuine screenshots or demo results. Claims must match what
was actually deployed and tested.
