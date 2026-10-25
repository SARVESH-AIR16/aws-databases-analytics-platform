# AWS Databases and Analytics Platform — Implementation Roadmap

## Objective

Build and test the integrated AWS platform defined below. Keep the full target
architecture; mark each component honestly as drafted, tested locally, deployed,
or tested in AWS.

## Locked network architecture

### Application VPC
- CIDR `10.0.0.0/16`
- Public subnet `10.0.1.0/24` in `ap-south-1a`
- Private subnet A `10.0.2.0/24` in `ap-south-1a`
- Private subnet B `10.0.3.0/24` in `ap-south-1b`
- Internet Gateway and public route table, private routes, access controls
- Planned app compute, RDS/Aurora, RDS Proxy, ElastiCache and DAX

### Analytics VPC
- CIDR `10.1.0.0/16`
- Private subnet A `10.1.1.0/24` in `ap-south-1a`
- Private subnet B `10.1.2.0/24` in `ap-south-1b`
- Private routing, S3 gateway endpoint, analytics services and optional worker

### Network requirements
- Non-overlapping CIDR blocks and routes for VPC peering
- No NAT Gateway by default and no automatic public IPv4 assignment
- Least-privilege security groups and IAM
- Managed service access and endpoints designed explicitly
- VPC peering is not transitive

## Module 1 — Relational databases

Optional RDS PostgreSQL and Aurora PostgreSQL Terraform configuration with
private subnet group, encryption, database access controls and synthetic schema.
Validate locally; live connectivity test remains pending approval and deployment.

## Module 2 — Availability and reads

Optional Multi-AZ, RDS PostgreSQL read replica and Aurora reader settings.
Test supported behaviour after a cost-reviewed deployment.

## Module 3 — Database connections

Optional RDS Proxy, connection path, backups and recovery guidance.
Test connections and recovery after a cost-reviewed deployment.

## Module 4 — DynamoDB

Optional on-demand orders table with a composite key, status/date GSI, limited
EC2 application role, sample data and offline schema checks. The stack is disabled
by default. Live table operations are pending a reviewed deployment.

## Module 5 — Caching

Optional Valkey and DAX Terraform configuration, encryption and local static/offline checks are added. Both stacks are disabled and not deployed. Live integration, latency testing and current regional pricing review remain pending.

## Module 6 — Analytics foundations

The optional analytics module adds:

- A private S3 Parquet data lake with SSE-S3, public-access blocks, HTTPS-only
  policy, bucket-owner-enforced ownership, versioning and lifecycle cleanup.
- A Glue Data Catalog database and an optional, unscheduled Parquet crawler.
- An Athena workgroup with enforced encrypted result output and a 50 MiB per-query
  scanned-data cutoff by default.
- An optional private, encrypted, single-node provisioned Redshift cluster for
  Spectrum integration, using a managed admin password and read-only S3/Glue IAM.

All analytics, crawler and Redshift switches default to false. Local tests and
Parquet/SQL examples can be validated without AWS. The Redshift demo is billable
while running, and the module's S3 bucket is configured to empty on Terraform
destroy; review the stage guide before an approved deployment.

## Module 7 — Streaming and ingestion

The optional streaming module adds:

- A provisioned Kinesis Data Stream with one shard and 24-hour retention by default,
  plus server-side encryption using the AWS-managed Kinesis KMS key.
- An optional Firehose consumer that reads the configured stream and delivers
  GZIP-compressed records to the Module 6 analytics S3 bucket.
- Bounded S3 buffering, time-partitioned success output, a dedicated delivery-error
  prefix, and seven-day lifecycle expiry for both streaming prefixes.
- Firehose role trust restricted by account and delivery-stream ARN, Kinesis read
  permissions scoped to the stream, constrained KMS decrypt conditions, and S3
  object access restricted to the two delivery prefixes.
- A producer-policy JSON output template with scoped KMS data-key generation and local synthetic NDJSON validation.

Both Kinesis and Firehose switches default to false. Firehose requires the Kinesis
and analytics stacks. The stream's provisioned shard can incur ongoing charges, and
Firehose charges depend on ingestion; review current regional pricing and a fresh
Terraform plan before an explicitly approved temporary demo. Local simulation does
not prove AWS ingestion or delivery.

## Module 8 — Database migration

Implement an AWS DMS migration test and validate migrated records and cleanup.

## Cross-cutting gates

1. Use appropriately permissioned IAM identities and protect secrets.
2. Format and validate Terraform and run static/functional tests.
3. Generate a fresh plan under the intended project identity.
4. Review current regional pricing and possible ongoing charges.
5. Require explicit approval before AWS deployment.
6. Test actual deployed behaviour before claiming success.
7. Clean up temporary resources and verify the cleanup.
8. Keep status labels accurate.

## Verified status at this stage

- The two-VPC/five-subnet CIDR plan and network-hardening Terraform configuration
  passed local validation; no network resources have been applied.
- Relational, DynamoDB, caching, and analytics configurations are optional and
  disabled by default; reported local validation/static checks passed.
- Module 7 streaming configuration and local checks have been added on this
  checkout; run the validation commands before staging or committing it.
- No AWS resources have been deployed by this project based on the reported runs.

## Portfolio deliverables

Root README, module guides, architecture diagram, Terraform code, local and live
validation evidence, synthetic data, cost/security/cleanup documentation and real
screenshots or demo results.
