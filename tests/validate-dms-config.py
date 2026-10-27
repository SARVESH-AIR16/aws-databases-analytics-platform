#!/usr/bin/env python3
"""Static guardrails for optional AWS DMS resources; no AWS API calls."""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
INFRA = ROOT / "infrastructure"
FILES = {
    name: (INFRA / name).read_text(encoding="utf-8")
    for name in (
        "dms-variables.tf", "dms-stack.tf", "dms-iam.tf",
        "dms-endpoints.tf", "dms-task.tf", "dms-outputs.tf",
        "analytics-stack.tf", "relational-stack.tf"
    )
}


def need(condition: bool, description: str) -> None:
    if not condition:
        print(f"FAIL: {description}")
        raise SystemExit(1)
    print(f"PASS: {description}")


vars_tf = FILES["dms-variables.tf"]
stack = FILES["dms-stack.tf"]
iam = FILES["dms-iam.tf"]
endpoints = FILES["dms-endpoints.tf"]
task = FILES["dms-task.tf"]
analytics = FILES["analytics-stack.tf"]
relational = FILES["relational-stack.tf"]

need(bool(re.search(r'variable\s+"enable_dms_stack"\s*\{[^}]*default\s*=\s*false', vars_tf, re.S)), "DMS stack disabled by default")
need(bool(re.search(r'variable\s+"enable_dms_task_start"\s*\{[^}]*default\s*=\s*false', vars_tf, re.S)), "Full-load task remains stopped by default")
need("var.enable_rds_stack && var.enable_analytics_stack" in stack and "!var.rds_manage_master_user_password" in stack, "DMS prerequisites guard requires RDS, analytics S3, and manual source credentials")
need('replication_instance_class  = var.dms_replication_instance_class' in stack and 'publicly_accessible         = false' in stack, "Replication instance uses configurable class and is private")
need('multi_az                    = var.dms_multi_az' in stack and 'allocated_storage           = var.dms_allocated_storage_gib' in stack, "Multi-AZ is explicitly configurable and storage bounded by validated input")
need('subnet_ids = [' in stack and 'aws_subnet.application_private.id' in stack and 'aws_subnet.application_private_b.id' in stack, "DMS subnet group uses two private application subnets")
need('egress {' in stack and 'prefix_list_ids = [aws_vpc_endpoint.s3_application.prefix_list_id]' in stack and 'security_groups = [aws_security_group.database.id]' in stack and 'No default allow-all egress is retained' not in stack, "DMS security group has only inline PostgreSQL/S3 gateway egress rules")
need('referenced_security_group_id = aws_security_group.dms[0].id' in stack and 'from_port                    = 5432' in stack, "Database ingress from DMS is restricted to the DMS security group on PostgreSQL port")
need('name               = "dms-vpc-role"' in iam and 'AmazonDMSVPCManagementRole' in iam and 'name               = "dms-cloudwatch-logs-role"' in iam and 'AmazonDMSCloudWatchLogsRole' in iam, "Required DMS VPC and CloudWatch Logs service roles/policies are configured")
need('s3:GetBucketLocation' in iam and 'sid       = "GetAnalyticsBucketLocation"' in iam, "S3 bucket location permission is independent of prefix conditions")
need('variable = "s3:prefix"' in iam and 'data/dms-migration/*' in iam and 'aws_s3_bucket.analytics_lake[0].arn}/data/dms-migration/*' in iam, "S3 list and object permissions are scoped to the DMS migration prefix")
need('ssl_mode      = "require"' in endpoints and 'password      = var.rds_master_password' in endpoints, "PostgreSQL source endpoint requires SSL and uses the protected sensitive password variable")
write_statement = re.search(
    r'statement\s*\{\s*sid\s*=\s*"WriteAndVerifyDMSMigrationObjects".*?\n\s*\}',
    iam,
    re.S,
)
need(
    bool(write_statement)
    and '"s3:PutObjectAcl"' in write_statement.group(0)
    and '"s3:PutObjectTagging"' in write_statement.group(0)
    and 'data/dms-migration/*' in write_statement.group(0),
    "DMS S3 target ACL/tagging permissions are scoped to the migration prefix",
)
need('data_format             = "parquet"' in endpoints and 'encryption_mode         = "SSE_S3"' in endpoints and 'bucket_folder           = "data/dms-migration"' in endpoints, "S3 target writes encrypted Parquet to a dedicated prefix")
need('"schema-name" = "public"' in task and '"table-name"  = "orders"' in task and 'migration_type           = "full-load"' in task, "Task is a full-load migration scoped to public.orders")
need('start_replication_task = var.enable_dms_task_start' in task, "Task start is explicitly gated by its opt-in variable")
need('id     = "expire-dms-migration-data"' in analytics and 'prefix = "data/dms-migration/"' in analytics, "DMS output has an S3 lifecycle expiry rule")
need('resource "aws_db_instance" "primary_manual"' in relational and 'local.rds_primary_address' in endpoints, "DMS source is wired to the explicit-credential RDS PostgreSQL instance")
print("PASS: DMS static guardrails passed.")
