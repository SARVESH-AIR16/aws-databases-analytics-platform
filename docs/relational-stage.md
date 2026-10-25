# Relational database stage — Modules 1–3

## Scope implemented as optional Terraform configuration

- Private RDS PostgreSQL primary using the application VPC's two private subnets.
- Encryption at rest, private-only access, backups, minor version updates and tags.
- Optional Multi-AZ standby for RDS.
- Optional same-region read replica for RDS PostgreSQL.
- Optional RDS Proxy with TLS-required client connections and a narrowly scoped role to retrieve its credential secret.
- Optional Aurora PostgreSQL cluster with a writer and optional reader instance.
- Outputs for private database/proxy endpoints.

## Cost controls

Every database/compute resource is disabled by default. `enable_rds_stack=false`
and `enable_aurora_stack=false` mean this module adds no database, proxy, or
Aurora compute resources to the default plan. Turning these on can create
ongoing charges for RDS, Secrets Manager, RDS Proxy, Aurora storage and Aurora
instances. Multi-AZ, RDS read replicas and Aurora reader instances add cost.
Verify current ap-south-1 prices before enabling any of these options.

The development configuration sets deletion protection off and skips final
snapshots to support cleanup of synthetic learning data. Do not use these
settings for production data. Automated backups and storage can still incur
charges while resources exist.

## Credentials and read replica compatibility

By default, RDS manages the master password in Secrets Manager. AWS documents
that RDS-managed master credentials are not compatible with creating a read
replica for PostgreSQL. To test the optional read replica, set
`rds_manage_master_user_password=false` and provide a strong password through
`TF_VAR_rds_master_password` in the current shell. Do not put passwords in a
`.tfvars` file or commit them. In this mode, Terraform state contains sensitive
password data, so keep the local state protected, encrypted at rest and ignored
by Git. Never upload the state file.

For the no-proxy configuration, application-to-database access is allowed only
through an explicit security-group reference. When RDS Proxy is enabled, the
intended path is application → RDS Proxy → RDS writer. The proxy is not attached
to a read replica; the replica is for read-scaling demonstrations only.

## Validation and enablement

1. Keep both stack toggles false for the baseline validation.
2. Validate Terraform and inspect the plan.
3. Verify permissions for RDS, IAM role/policy creation and Secrets Manager.
4. Review current Region-specific pricing and estimated duration.
5. Obtain explicit deployment approval before enabling a cost-bearing stack.
6. After an approved deployment, test connection, read-only replica behaviour,
   backup settings, proxy TLS/client connectivity and cleanup.

Never claim a database or proxy is deployed until the AWS resource and its
behaviour have been verified.
