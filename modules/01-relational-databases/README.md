# Module 01 — Relational databases

## Scope
Optional Terraform resources for RDS PostgreSQL and Aurora PostgreSQL, private
subnet placement, encryption at rest, credential management, backups and secure
network access. Both stacks are disabled by default to avoid accidental cost.

## RDS PostgreSQL toggle
`enable_rds_stack = true` in a reviewed local `*.tfvars` file or via a safe
CLI/environment configuration enables the primary RDS instance. Review class,
storage limits, backup retention, credential mode and regional pricing first.

## Aurora PostgreSQL toggle
`enable_aurora_stack = true` enables the Aurora cluster and writer instance.
`enable_aurora_reader = true` adds a separate reader instance and additional
ongoing cost. Aurora provisioned compute and storage can be materially more
expensive than a small RDS test instance.

## Acceptance tests
- Terraform format and validation pass.
- DB subnet group spans `ap-south-1a` and `ap-south-1b`.
- Database has encryption enabled and is not publicly accessible.
- After deployment approval, connect using an authorized credential path and
  run a sample create/insert/select/delete sequence with synthetic data.
