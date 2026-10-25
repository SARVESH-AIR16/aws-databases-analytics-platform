# AWS Databases and Analytics Platform

A Terraform-managed AWS portfolio project covering network segmentation,
relational and NoSQL databases, caching, analytics, streaming, migration,
security controls, automated validation and cost-conscious operations.

## Public repository

The project is published on [`main`](https://github.com/SARVESH-AIR16/aws-databases-analytics-platform).

## Current implementation status

| Area | Status |
|---|---|
| Two-VPC, five-subnet foundation | Terraform validation and CIDR checks passed locally |
| Network security groups and gateway endpoints | Terraform validation passed; 45 additions in the saved plan; not deployed |
| RDS PostgreSQL configuration | Optional Terraform resources added; disabled by default; not deployed or integration-tested |
| Aurora PostgreSQL configuration | Optional Terraform resources added; disabled by default; not deployed or integration-tested |
| Multi-AZ, read replica and Aurora reader options | Coded as optional settings; disabled by default; not tested in AWS |
| RDS Proxy | Optional configuration drafted; disabled by default; not tested in AWS |
| DynamoDB operations, caching, analytics, streaming and DMS | Planned modules; implementation and evidence still required |

A valid Terraform configuration or plan does not prove that resources have been
created or that the application works end-to-end. Update status only after
reproducible testing and evidence.

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
public IPv4 addresses. See [architecture overview](docs/architecture.md),
[network design](docs/network-design.md), and
[diagram source](docs/architecture-diagram.mmd).

## Eight project modules

1. **Relational databases** — RDS PostgreSQL, Aurora PostgreSQL and synthetic schema.
2. **Availability and reads** — Multi-AZ, RDS read replica and Aurora reader options.
3. **Database connections** — RDS Proxy, backups and recovery.
4. **DynamoDB** — NoSQL data model and operations.
5. **Caching** — ElastiCache and DAX.
6. **Analytics foundations** — S3 Parquet, Glue, Athena and Redshift.
7. **Streaming and ingestion** — Kinesis and Firehose.
8. **Database migration** — AWS DMS and migration validation.

Modules 1–3 have optional Terraform code drafted, but all database and proxy
flags default to `false`. Their AWS deployment and functional tests remain pending.
Modules 4–8 remain planned and require implementation, testing and evidence.

## Local validation

Prerequisites: Terraform, AWS CLI, Python 3 and Git.

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 scripts/validate-cidrs.py
python3 tests/validate-relational-config.py
```

To generate a fresh plan after validating the AWS identity and permissions:

```bash
AWS_PROFILE=ghost-hunter-cli AWS_REGION=ap-south-1 \
  terraform -chdir=infrastructure plan
```

The relational stacks are disabled by default. Do not enable them until you have
reviewed current Mumbai-region pricing and the required permissions. Planning is
not deployment; inspect all resource actions before any apply.

## Security and cost

- Use an appropriately permissioned non-root identity; prefer temporary credentials
  when practical. Never commit keys, state, saved plans or secret-bearing tfvars.
- If RDS-managed master credentials are enabled, PostgreSQL read replica creation
  is not supported. The read-replica option requires manually managed credentials,
  which means local Terraform state can contain sensitive password material.
- The RDS configuration is private, encrypted at rest, and allows the optional
  RDS Proxy connection path only through security-group references. Proxy requires TLS.
- The bastion SSH ingress is disabled unless a trusted `admin_cidr` is explicitly set.
  Never set it to `0.0.0.0/0`.
- Gateway endpoints provide a network path, not IAM authorization. AWS states S3 and
  DynamoDB gateway endpoints have no additional endpoint charge; normal service
  usage costs remain.
- RDS/Aurora, proxy, cache, DAX, Redshift, DMS, Kinesis/Firehose, EC2, public IPv4,
  interface endpoints, Secrets Manager and data transfer can incur charges.
- Budget alerts are not hard spending caps. Define cleanup before each test and verify it.

## Portfolio evidence

The completed project will include reproducible configuration and tests, synthetic
sample data, architecture evidence, module documentation, cost/security/cleanup
instructions, and genuine screenshots or demo results. Claims must match what was
actually deployed and tested.
