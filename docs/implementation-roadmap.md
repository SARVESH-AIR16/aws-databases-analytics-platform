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

Implement S3 Parquet, Glue Data Catalog, Athena queries and Redshift integration.

## Module 7 — Streaming and ingestion

Implement Kinesis and Firehose with a defined destination and synthetic-record tests.

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

- The two-VPC/five-subnet configuration and CIDR validator passed locally.
- The pre-Module-5 network-hardening plan proposed 45 additions, zero changes and
  zero deletions; not applied. Module 5 removes two plaintext DAX security-group rules,
  so regenerate a fresh plan before any deployment.
- Relational configuration guardrails passed; RDS/Aurora/Proxy are disabled and
  no database services were in the plan.
- DynamoDB optional configuration and offline checks passed before the last commit; stack disabled by default.
- Caching optional configuration has been added locally by the Module 5 installer; validate and test before committing.
- No AWS resources have been deployed by this project based on the reported runs.

## Portfolio deliverables

Root README, module guides, architecture diagram, Terraform code, local and live
validation evidence, synthetic data, cost/security/cleanup documentation and real
screenshots or demo results.
