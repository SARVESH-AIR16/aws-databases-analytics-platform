# Module 03 — Database connections, backups and recovery

The optional `enable_rds_proxy` setting creates RDS Proxy for the RDS PostgreSQL
writer. The proxy is private to the application VPC, requires TLS, and uses an
IAM role with access limited to the credential secret it needs.

RDS Proxy supports the writer target, not the PostgreSQL read replica in a
replication configuration. Connect application clients to the proxy endpoint
when the proxy is enabled. Otherwise the no-proxy lab path uses a direct private
connection explicitly restricted by security group.

Backup retention is configured for seven days on the RDS primary and Aurora
cluster. The project must test restore/recovery only after explicit approval;
backup configuration alone is not proof of successful recovery.

Keep database credentials out of source control. Do not publish Terraform state,
plan files or `.tfvars` with credentials. Review Secrets Manager costs and IAM
permissions before enabling this stack.
