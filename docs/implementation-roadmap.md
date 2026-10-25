# AWS Databases and Analytics Platform — Implementation Roadmap

## Objective

Implement and test an integrated AWS platform covering relational databases,
availability, connection management, NoSQL, caching, analytics, streaming and
migration. Terraform manages the infrastructure and Python provides local checks.

## Locked network architecture

Application VPC: `10.0.0.0/16`; public subnet `10.0.1.0/24` in `ap-south-1a`;
private subnet A `10.0.2.0/24` in `ap-south-1a`; private subnet B `10.0.3.0/24`
in `ap-south-1b`.

Analytics VPC: `10.1.0.0/16`; private subnet A `10.1.1.0/24` in `ap-south-1a`;
private subnet B `10.1.2.0/24` in `ap-south-1b`.

Network layer: Internet Gateway and public route, private route tables, VPC
peering with bidirectional private routes, tier-specific security groups, an S3
gateway endpoint in each VPC and a DynamoDB gateway endpoint in the application VPC.
No NAT Gateway by default. No automatic public IPv4 assignment. Gateway endpoints
provide network access only; IAM and resource policies still govern permissions.

## Module 1 — Relational databases

Implement RDS/Aurora, subnet groups, encryption, credentials handling, database
security and a synthetic-data schema. Validate configuration and test connectivity
if deployment is approved.

## Module 2 — Availability and reads

Implement suitable Multi-AZ and read-replica options. Test supported availability
and read behaviour and document limitations.

## Module 3 — Database connections

Implement RDS Proxy, connection handling, backups and recovery. Test connections
and document a recovery exercise where feasible.

## Module 4 — DynamoDB

Implement table keys, access patterns, synthetic records and data validation.
Document capacity/index choices and request costs.

## Module 5 — Caching

Implement the selected ElastiCache and DAX designs as appropriate. Measure cache
hits, misses and latency using repeatable tests.

## Module 6 — Analytics foundations

Implement S3 Parquet storage, Glue Data Catalog, Athena queries and Redshift
integration using synthetic data.

## Module 7 — Streaming and ingestion

Implement Kinesis and Firehose with a defined destination. Validate delivery of
synthetic records and document service/network access.

## Module 8 — Database migration

Implement an AWS DMS test, validate migrated records, and document cleanup and
known limitations.

## Cross-cutting gates

1. Use an appropriately permissioned non-root identity.
2. Format and validate Terraform and run local tests.
3. Generate a fresh plan under the intended profile and inspect all actions.
4. Review current regional prices, cleanup and ongoing costs before applying.
5. Obtain explicit approval before AWS deployment.
6. Test real deployed behaviour before claiming success.
7. Verify cleanup and mark each module planned, implemented, tested or not deployed.

## Verified status before the network hardening patch

- Public GitHub repository created and the initial commit pushed to `main`.
- Existing two-VPC/five-subnet foundation and CIDR validator passed local checks.
- Previous baseline plan proposed 19 additions, zero changes and zero deletions.
- That plan has not been applied.
- This security-group and gateway-endpoint layer is a proposed local configuration
  update; validate it and generate a fresh plan before deployment.
- Database, cache, analytics, streaming and migration services are not deployed.

## Portfolio deliverables

Root README, module guides, architecture diagram, reproducible Terraform checks,
synthetic data, actual test outputs, cost/security/cleanup guides and genuine
screenshots or demo evidence. Claims must accurately reflect what works.
