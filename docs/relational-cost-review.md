# Relational stage cost review gate

Before enabling database flags, check the current AWS Pricing Calculator and
pricing pages for the Mumbai (`ap-south-1`) Region. Review:

- RDS PostgreSQL instance-hours, gp3 storage and any allocated IOPS.
- Additional standby charges when `rds_multi_az=true`.
- Additional instance-hours and storage for an RDS read replica.
- RDS Proxy usage while `enable_rds_proxy=true`.
- Aurora storage and writer/reader instance-hours.
- Secrets Manager secret-month charges and API usage.
- Backup storage beyond included allowances and retained snapshots.
- CloudWatch, data transfer and other ancillary usage.

All relational flags default to false. Budgets and alerts are notifications, not
hard spending caps. Document the test scope, duration and cleanup procedure
before enabling a relational feature.
