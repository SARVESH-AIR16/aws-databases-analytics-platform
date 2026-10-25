# Module 02 — Availability and reads

## RDS PostgreSQL
`rds_multi_az` enables a Multi-AZ standby for the RDS instance. This improves
availability but adds ongoing cost. `enable_rds_read_replica` creates a separate
replica for read-scaling experiments and also adds ongoing cost.

AWS does not support creating a PostgreSQL read replica when the source
instance uses RDS-managed master credentials in Secrets Manager. To enable the
replica, disable RDS-managed master credentials and provide
`TF_VAR_rds_master_password` locally. Terraform state then contains sensitive
password data and must be protected.

## Aurora PostgreSQL
Aurora uses a cluster writer endpoint, and `enable_aurora_reader` adds a cluster
reader instance for read-scaling tests. This is a cluster reader, not a separate
RDS instance read replica.

## Evidence after approved deployment
Document tested reader/writer endpoints, sample row consistency, replication
lag if observable, configured backup retention, and observed failover behaviour.
Never claim failover has been tested merely because Multi-AZ is enabled.
