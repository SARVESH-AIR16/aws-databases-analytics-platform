# Module 8 — AWS DMS, all opt-in and privately networked.
locals {
  dms_resources_enabled = var.enable_dms_stack && var.enable_rds_stack && var.enable_analytics_stack && !var.rds_manage_master_user_password
}

# Keep a fail-closed precondition separate from resource counts: if DMS is requested
# without its source/target stacks or a manually managed source password, apply fails
# before the DMS resources can be created.
resource "terraform_data" "dms_prerequisite_guard" {
  count = var.enable_dms_stack ? 1 : 0

  input = {
    enable_rds_stack                = var.enable_rds_stack
    enable_analytics_stack          = var.enable_analytics_stack
    rds_manage_master_user_password = var.rds_manage_master_user_password
  }

  lifecycle {
    precondition {
      condition     = var.enable_rds_stack && var.enable_analytics_stack
      error_message = "enable_dms_stack=true requires both enable_rds_stack=true and enable_analytics_stack=true."
    }
    precondition {
      condition     = !var.rds_manage_master_user_password
      error_message = "This DMS source endpoint uses explicit PostgreSQL endpoint credentials. Set rds_manage_master_user_password=false and supply a strong TF_VAR_rds_master_password; protect Terraform state because endpoint passwords are stored in it."
    }
    precondition {
      condition     = nonsensitive(length(var.rds_master_password)) >= 16
      error_message = "When DMS is enabled, provide a strong RDS master password of at least 16 characters via TF_VAR_rds_master_password or an untracked tfvars file."
    }
  }
}

resource "terraform_data" "dms_task_start_guard" {
  count = var.enable_dms_task_start ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.dms_resources_enabled && nonsensitive(length(var.rds_master_password)) >= 16
      error_message = "enable_dms_task_start=true requires a fully configured DMS stack, RDS, analytics S3, and a valid source password."
    }
  }
}

resource "aws_security_group" "dms" {
  count = local.dms_resources_enabled ? 1 : 0

  name                   = "db-analytics-dms-sg"
  description            = "Private AWS DMS replication instance; PostgreSQL and S3 gateway egress only."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  # Inline egress rules are intentionally used only for this SG so its default
  # allow-all egress is removed and not mixed with standalone egress rule resources.
  egress {
    description     = "DMS source connection to private PostgreSQL only."
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
  }

  egress {
    description     = "DMS target traffic to S3 using the application VPC gateway endpoint."
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3_application.prefix_list_id]
  }

  tags = {
    Name   = "db-analytics-dms-sg"
    Module = "migration"
  }

  depends_on = [terraform_data.dms_prerequisite_guard]
}

resource "aws_vpc_security_group_ingress_rule" "database_from_dms" {
  count = local.dms_resources_enabled ? 1 : 0

  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.dms[0].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Private PostgreSQL source connection from AWS DMS only."
}

resource "aws_dms_replication_subnet_group" "private" {
  count = local.dms_resources_enabled ? 1 : 0

  replication_subnet_group_id          = "db-analytics-dms-subnets"
  replication_subnet_group_description = "Private application subnets across two Availability Zones for DMS."
  subnet_ids = [
    aws_subnet.application_private.id,
    aws_subnet.application_private_b.id
  ]

  tags = {
    Name   = "db-analytics-dms-subnets"
    Module = "migration"
  }

  depends_on = [terraform_data.dms_prerequisite_guard]
}

resource "aws_dms_replication_instance" "full_load" {
  count = local.dms_resources_enabled ? 1 : 0

  replication_instance_id     = "db-analytics-dms-repl"
  replication_instance_class  = var.dms_replication_instance_class
  allocated_storage           = var.dms_allocated_storage_gib
  replication_subnet_group_id = aws_dms_replication_subnet_group.private[0].id
  vpc_security_group_ids      = [aws_security_group.dms[0].id]
  publicly_accessible         = false
  multi_az                    = var.dms_multi_az
  auto_minor_version_upgrade  = true
  apply_immediately           = false

  tags = {
    Name   = "db-analytics-dms-repl"
    Module = "migration"
  }

  depends_on = [
    terraform_data.dms_prerequisite_guard,
    aws_iam_role_policy_attachment.dms_vpc,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs
  ]
}
