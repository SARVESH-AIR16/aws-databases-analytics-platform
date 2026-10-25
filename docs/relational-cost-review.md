# Relational stage cost review gate

Before enabling database flags, use the AWS Pricing Calculator or current AWS
pricing pages for the Mumbai (`ap-south-1`) Region. Review:

- RDS PostgreSQL instance-hours and gp3 storage/allocated IOPS, if applicable.
- The additional standby charge when `rds_multi_az=true`.
- Additional instance-hours/storage for `enable_rds_read_replica=true`.
- RDS Proxy hours/capacity when `enable_rds_proxy=true`.
- Aurora cluster storage and writer/reader instance-hours when
  `enable_aurora_stack=true` and `enable_aurora_reader=true`.
- Secrets Manager secret-month charges and API usage.
- Backup storage beyond included allowances and any retained snapshots.
- CloudWatch logs/metrics, data transfer and any other ancillary usage.

These toggles default to false. Budgets and alerts are notifications, not hard
spending caps. Keep the relational flags disabled until the approved test scope,
expected duration and cleanup procedure are documented.
