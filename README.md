# AWS Databases and Analytics Platform

An AWS portfolio project for designing and implementing an integrated database and analytics platform with Terraform, segmented networking, data services, validation, security controls, and cost-conscious operations.

## Current verified status

| Area | Status |
|---|---|
| Two-VPC, five-subnet network configuration | Terraform validation passed locally |
| CIDR validation | Passed locally |
| Most recent Terraform plan | 19 additions, 0 changes, 0 deletions |
| AWS network deployment | Not deployed |
| Database and analytics modules | Not yet implemented and tested end to end |
| Local Git repository | Initialized on `main`; no remote configured yet |

A valid Terraform plan is not evidence that resources have been deployed or that an end-to-end workflow works. Status must be updated only after implementation and testing.

## Target architecture

The target design contains two non-overlapping VPCs connected through VPC peering. The application VPC is intended to contain application and database components. The analytics VPC is intended to host private analytics workloads. Managed AWS services require service-specific connectivity and permissions; VPC peering alone does not provide universal access to them.

See [architecture overview](docs/architecture.md), [network design](docs/network-design.md), and [architecture diagram source](docs/architecture-diagram.mmd).

## Locked network address plan

### Application VPC

- VPC: `10.0.0.0/16`
- Public subnet: `10.0.1.0/24` in `ap-south-1a`
- Private subnet A: `10.0.2.0/24` in `ap-south-1a`
- Private subnet B: `10.0.3.0/24` in `ap-south-1b`

### Analytics VPC

- VPC: `10.1.0.0/16`
- Private subnet A: `10.1.1.0/24` in `ap-south-1a`
- Private subnet B: `10.1.2.0/24` in `ap-south-1b`

The network Terraform configuration currently describes VPCs, subnets, an Internet Gateway, route tables, associations, VPC peering, and private routes. Security groups, service connectivity, and deployment readiness require additional review. The configured subnets do not automatically assign public IPv4 addresses. No NAT Gateway is included by default.

## Eight project modules

| Module | Scope | Status |
|---|---|---|
| 1. Relational databases | RDS/Aurora and schema | Planned |
| 2. Availability and reads | Multi-AZ and read replicas | Planned |
| 3. Database connections | RDS Proxy, backups and recovery | Planned |
| 4. DynamoDB | NoSQL data model and operations | Planned |
| 5. Caching | ElastiCache and DAX | Planned |
| 6. Analytics foundations | S3 Parquet, Glue, Athena and Redshift | Planned |
| 7. Streaming and ingestion | Kinesis and Firehose | Planned |
| 8. Database migration | AWS DMS and migration validation | Planned |

## Technology

- Amazon Web Services
- Terraform
- AWS CLI
- Python for CIDR validation and local tests
- Git

## Local validation

Prerequisites: Terraform, AWS CLI, Python 3, and Git.

From the repository root:

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 scripts/validate-cidrs.py
```

To create a fresh AWS plan after verifying credentials and permissions:

```bash
AWS_PROFILE=ghost-hunter-cli \
AWS_REGION=ap-south-1 \
terraform -chdir=infrastructure plan
```

Planning does not deploy resources. Review the planned actions before any apply operation. Do not commit Terraform state, plan files, credentials, or secret-bearing variable files.

## Security and cost approach

- Use an appropriately permissioned non-root AWS identity.
- Review IAM permissions, security groups, and managed-service connectivity before deployment.
- Do not assume VPC peering is transitive.
- Review current regional pricing before each deployment stage.
- Remember that budgets and alerts are not hard spending caps.
- Database, cache, migration, streaming, and analytics services can incur charges.
- Use synthetic data, short test windows where sensible, and verify resource cleanup.

## Portfolio evidence

The finished repository should include an architecture diagram reflecting actual status, reproducible infrastructure and test instructions, service-specific documentation, synthetic datasets, genuine test results, cost and cleanup documentation, and authentic screenshots or demo evidence. Claims about deployed functionality must match what was actually deployed and tested.
