# AWS Databases and Analytics Platform

A Terraform-managed AWS portfolio project covering network segmentation,
relational and NoSQL databases, caching, analytics, streaming, migration,
security controls, local validation and cost-conscious operations.

## Repository status

The public repository has been created and the initial commit is published on
[`main`](https://github.com/SARVESH-AIR16/aws-databases-analytics-platform).
Follow-up network-hardening changes are in progress locally and must be committed
and pushed after validation.

## Current implementation status

| Area | Status |
|---|---|
| Two-VPC/five-subnet foundation | Earlier Terraform validation passed locally |
| CIDR validation | Passed locally |
| Baseline network plan | 19 additions, 0 changes, 0 deletions; not applied |
| Security groups and gateway endpoints | Proposed update; new local validation/plan still required |
| AWS network deployment | Not deployed |
| Database and analytics modules | Not yet deployed or tested end-to-end |

A successful Terraform validate or plan is not evidence that resources were
created or an application works end-to-end. Update status only after testing.

## Locked address plan

### Application VPC — `10.0.0.0/16`

- Public subnet `10.0.1.0/24`, `ap-south-1a`
- Private subnet A `10.0.2.0/24`, `ap-south-1a`
- Private subnet B `10.0.3.0/24`, `ap-south-1b`

### Analytics VPC — `10.1.0.0/16`

- Private subnet A `10.1.1.0/24`, `ap-south-1a`
- Private subnet B `10.1.2.0/24`, `ap-south-1b`

The target design includes VPC peering, tier-specific security groups, an S3
Gateway endpoint in each VPC and a DynamoDB gateway endpoint in the application
VPC. No NAT Gateway is included by default; no subnet automatically assigns
public IPv4 addresses. See [the architecture overview](docs/architecture.md),
[network design](docs/network-design.md), and
[diagram source](docs/architecture-diagram.mmd).

## Eight project modules

1. Relational databases — RDS/Aurora and schema.
2. Availability and reads — Multi-AZ and read replicas.
3. Database connections — RDS Proxy, backups and recovery.
4. DynamoDB — NoSQL data model and operations.
5. Caching — ElastiCache and DAX.
6. Analytics foundations — S3 Parquet, Glue, Athena and Redshift.
7. Streaming and ingestion — Kinesis and Firehose.
8. Database migration — AWS DMS and migration validation.

These modules remain planned until their infrastructure, tests and evidence exist.

## Local validation

Prerequisites: Terraform, AWS CLI, Python 3 and Git.

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 scripts/validate-cidrs.py
```

To generate a fresh plan after validating the AWS identity and permissions:

```bash
AWS_PROFILE=ghost-hunter-cli AWS_REGION=ap-south-1 \
  terraform -chdir=infrastructure plan
```

Planning is not deployment. Inspect all resource actions before any apply.

## Security and cost

- Use an appropriately permissioned non-root identity; prefer temporary credentials
  when practical. Never commit keys, state, saved plans or secret-bearing tfvars.
- The bastion SSH ingress is disabled unless a trusted `admin_cidr` is explicitly set.
  Never set it to `0.0.0.0/0`.
- Gateway endpoints provide a network path, not IAM authorization.
- AWS states S3/DynamoDB gateway endpoints have no additional endpoint charge;
  normal service usage costs remain. Check regional service pricing before deployment.
- RDS/Aurora, proxy, cache, DAX, Redshift, DMS, Kinesis/Firehose, EC2, public IPv4,
  interface endpoints and data transfer can incur charges.
- Budget alerts are not hard spending caps. Define cleanup before each test and verify it.

## Portfolio evidence

The completed project will include reproducible configuration and tests, synthetic
sample data, architecture evidence, module documentation, cost/security/cleanup
instructions, and genuine screenshots or demo results. Claims must match what was
actually deployed and tested.
