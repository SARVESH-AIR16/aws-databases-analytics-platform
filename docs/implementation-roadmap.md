# AWS Databases and Analytics Platform — Implementation Roadmap

## Objective

Build and test an integrated AWS platform covering networking, relational and NoSQL databases, caching, analytics, streaming, and database migration. Use Terraform for reproducible infrastructure.

## Locked network architecture

### Application VPC

- CIDR: `10.0.0.0/16`
- Public subnet: `10.0.1.0/24`, `ap-south-1a`
- Private subnet A: `10.0.2.0/24`, `ap-south-1a`
- Private subnet B: `10.0.3.0/24`, `ap-south-1b`
- Internet Gateway and public route table
- Private routing and security controls
- Planned application compute, RDS/Aurora, RDS Proxy, and ElastiCache

### Analytics VPC

- CIDR: `10.1.0.0/16`
- Private subnet A: `10.1.1.0/24`, `ap-south-1a`
- Private subnet B: `10.1.2.0/24`, `ap-south-1b`
- Private routing and service-specific access design
- Planned analytics services and optional worker

### Network requirements

- Keep VPC and subnet CIDRs non-overlapping.
- Configure VPC peering and routes in both directions.
- No NAT Gateway by default.
- No automatic public IPv4 assignment to configured subnets.
- Use least-privilege IAM and security groups.
- Design service access and endpoints individually.
- VPC peering is not transitive.
- Check the address plan against VPN, home, and corporate networks before deployment.

## Module 1 — Relational databases

Implement RDS/Aurora, subnet groups, encryption, credential handling, database access controls, and a synthetic-data schema. Acceptance: configuration validates and database connectivity and operations are tested if deployment is approved.

## Module 2 — Availability and reads

Implement and document appropriate Multi-AZ and read-replica options. Test supported availability and read behaviour and document limitations.

## Module 3 — Database connections

Implement RDS Proxy, connection handling, backups, and recovery procedures. Test connection behaviour and document a recovery exercise where feasible.

## Module 4 — DynamoDB

Implement table design, keys, access patterns, sample operations, data validation, and cost considerations.

## Module 5 — Caching

Implement the selected ElastiCache and DAX designs where appropriate. Measure cache hits, misses, and latency using repeatable tests.

## Module 6 — Analytics foundations

Create an S3 Parquet data path, Glue Data Catalog definitions, Athena queries, and Redshift integration using synthetic data.

## Module 7 — Streaming and ingestion

Implement Kinesis and Firehose with a defined destination. Validate delivery using synthetic records and observable evidence.

## Module 8 — Database migration

Document source and target requirements, configure an AWS DMS test, validate migrated records, and explain cleanup and known limitations.

## Cross-cutting completion gates

1. Review IAM permissions and secret handling.
2. Format and validate Terraform.
3. Run static, automated, and functional tests where available.
4. Generate a fresh plan under the intended project identity.
5. Review current regional pricing and ongoing charges.
6. Obtain explicit approval before deploying AWS resources.
7. Test actual deployed behaviour before claiming success.
8. Clean up temporary resources and verify cleanup.
9. Mark components accurately as planned, implemented, tested, or not deployed.

## Current verified status

- Two-VPC, five-subnet Terraform configuration passed validation.
- CIDR validation passed.
- A saved Terraform plan proposed 19 additions, zero changes, and zero deletions.
- The plan has not been applied.
- Database and analytics modules are not yet verified as deployed.

## Portfolio deliverables

- Root README and module-specific guides
- Architecture diagram aligned to implementation status
- Terraform source and reproducible validation steps
- Synthetic data and test results
- Security, cost, deployment, and cleanup documentation
- Genuine screenshots or demo evidence
- Honest description of implemented components and limitations
