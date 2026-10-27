# Live AWS Demo Verification and Cleanup

Date: 2026-10-27
Region: `ap-south-1`

## Deployment summary

- The temporary Terraform deployment completed successfully.
- The final provisioning apply added 11 resources and changed 0 resources.
- The reviewed destroy plan showed 0 to add, 0 to change and 73 to destroy.
- The destroy apply completed with 0 added, 0 changed and 73 destroyed.
- The temporary IAM deployment role and assume-role permission were subsequently removed.
- The repository, source code, documentation and screenshots were preserved.

## Services verified before cleanup

- **RDS PostgreSQL:** `db-analytics-postgres` was available; class `db.t4g.micro`;
  20 GB allocated storage; one-day backup retention; not publicly accessible.
- **EC2:** the analytics worker was running as a `t3.micro` instance.
- **ElastiCache Valkey:** the replication group was available.
- **DynamoDB:** `db-analytics-orders` was `ACTIVE`.
- **S3:** default server-side encryption was AES256.
- **AWS Glue Data Catalog:** database `dba_analytics_lake` existed.
- **Networking:** both project VPCs were verified and VPC peering was active.

## Cleanup verification

Terraform reported successful destruction of all 73 resources in its
deployment state.

Read-only checks after destruction reported:

- PostgreSQL database: not found.
- Valkey replication group: not found.
- DynamoDB orders table: not found.
- S3 lake bucket: not found.
- Glue catalog database: not found.
- Application VPC: not found.
- Analytics VPC: not found.
- Analytics worker: no live instance found.

These checks cover named project resources, not every resource in the AWS
account. They do not prove the bill is zero; billing information can take time
to update, so check the AWS Billing Console for delayed charges.

## Services not deployed in this demo

Aurora, RDS Proxy, the RDS read replica, DAX, Athena workgroup/crawler,
Redshift, Kinesis, Firehose and AWS DMS were not deployed as live services in
this demo. Their presence in Terraform code or passing local tests must not be
presented as evidence of live service operation.

## Screenshot evidence

The six screenshots captured before teardown are stored in `docs/screenshots/`:

- `01-vpc-peering.png`
- `02-ec2-instances.png`
- `03-rds-postgresql.png`
- `04-valkey-cache.png`
- `05-s3-encryption.png`
- `06-s3-public-access.png`

These are dated snapshots of the temporary deployment, not evidence that
resources remain running.
