locals {
  relational_stack_enabled = var.enable_rds_stack || var.enable_aurora_stack

  rds_primary_identifier = var.rds_manage_master_user_password ? try(aws_db_instance.primary[0].identifier, null) : try(aws_db_instance.primary_manual[0].identifier, null)
  rds_primary_arn        = var.rds_manage_master_user_password ? try(aws_db_instance.primary[0].arn, null) : try(aws_db_instance.primary_manual[0].arn, null)
  rds_primary_address    = var.rds_manage_master_user_password ? try(aws_db_instance.primary[0].address, null) : try(aws_db_instance.primary_manual[0].address, null)
  rds_proxy_secret_arn   = var.rds_manage_master_user_password ? try(aws_db_instance.primary[0].master_user_secret[0].secret_arn, null) : try(aws_secretsmanager_secret_version.rds_proxy_credentials[0].arn, null)
}

resource "aws_db_subnet_group" "relational" {
  count      = local.relational_stack_enabled ? 1 : 0
  name       = "db-analytics-relational-subnets"
  subnet_ids = [aws_subnet.application_private.id, aws_subnet.application_private_b.id]

  description = "Private subnets across two Availability Zones for relational database resources."

  tags = {
    Name = "db-analytics-relational-subnets"
  }
}

resource "aws_db_instance" "primary" {
  count = var.enable_rds_stack && var.rds_manage_master_user_password ? 1 : 0

  identifier                  = var.rds_instance_identifier
  engine                      = "postgres"
  port                        = 5432
  instance_class              = var.rds_instance_class
  db_name                     = var.rds_db_name
  username                    = var.rds_master_username
  manage_master_user_password = true
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  storage_encrypted           = true

  db_subnet_group_name   = aws_db_subnet_group.relational[0].name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.rds_multi_az

  backup_retention_period      = 7
  backup_window                = "17:00-18:00"
  maintenance_window           = "sun:18:00-sun:19:00"
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = false

  tags = {
    Name = var.rds_instance_identifier
  }

  lifecycle {
    precondition {
      condition     = var.rds_manage_master_user_password || length(var.rds_master_password) >= 16
      error_message = "Set TF_VAR_rds_master_password to a strong password of at least 16 characters, or enable RDS-managed master credentials."
    }

    precondition {
      condition     = !(var.enable_rds_read_replica && var.rds_manage_master_user_password)
      error_message = "AWS RDS-managed master passwords are incompatible with creating an RDS PostgreSQL read replica. Set rds_manage_master_user_password=false and provide rds_master_password when enabling the read replica."
    }
  }
}

resource "aws_db_instance" "primary_manual" {
  count = var.enable_rds_stack && !var.rds_manage_master_user_password ? 1 : 0

  identifier     = var.rds_instance_identifier
  engine         = "postgres"
  port           = 5432
  instance_class = var.rds_instance_class
  db_name        = var.rds_db_name
  username       = var.rds_master_username
  password       = var.rds_master_password

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.relational[0].name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.rds_multi_az

  backup_retention_period      = 1
  backup_window                = "17:00-18:00"
  maintenance_window           = "sun:18:00-sun:19:00"
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = false

  tags = {
    Name = var.rds_instance_identifier
  }

  lifecycle {
    precondition {
      condition     = length(var.rds_master_password) >= 16
      error_message = "When using explicit credentials, set TF_VAR_rds_master_password to a strong password of at least 16 characters. Keep Terraform state private."
    }

    precondition {
      condition     = !(var.enable_rds_read_replica && var.rds_manage_master_user_password)
      error_message = "AWS RDS-managed master passwords are incompatible with creating an RDS PostgreSQL read replica. Set rds_manage_master_user_password=false and provide rds_master_password when enabling the read replica."
    }
  }
}

resource "aws_db_instance" "read_replica" {
  count = var.enable_rds_stack && var.enable_rds_read_replica ? 1 : 0

  identifier                 = "${var.rds_instance_identifier}-read"
  replicate_source_db        = local.rds_primary_arn
  instance_class             = var.rds_instance_class
  publicly_accessible        = false
  db_subnet_group_name       = aws_db_subnet_group.relational[0].name
  vpc_security_group_ids     = [aws_security_group.database.id]
  port                       = 5432
  storage_encrypted          = true
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = true
  deletion_protection        = false

  tags = {
    Name = "${var.rds_instance_identifier}-read-replica"
    Role = "read-replica"
  }
}

resource "aws_secretsmanager_secret" "rds_proxy_credentials" {
  count = var.enable_rds_stack && var.enable_rds_proxy && !var.rds_manage_master_user_password ? 1 : 0

  name                    = "${var.rds_instance_identifier}-proxy-credentials"
  description             = "Database credentials for the portfolio RDS Proxy."
  recovery_window_in_days = 0

  tags = {
    Name = "${var.rds_instance_identifier}-proxy-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_proxy_credentials" {
  count = var.enable_rds_stack && var.enable_rds_proxy && !var.rds_manage_master_user_password ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_proxy_credentials[0].id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = var.rds_master_password
    engine   = "postgres"
    host     = local.rds_primary_address
    port     = 5432
    dbname   = var.rds_db_name
  })
}

resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_stack && var.enable_rds_proxy ? 1 : 0

  name = "db-analytics-rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "db-analytics-rds-proxy-role"
  }
}

resource "aws_iam_role_policy" "rds_proxy_secret_access" {
  count = var.enable_rds_stack && var.enable_rds_proxy ? 1 : 0

  name = "read-rds-proxy-credentials"
  role = aws_iam_role.rds_proxy[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = local.rds_proxy_secret_arn
    }]
  })
}

resource "aws_db_proxy" "rds" {
  count = var.enable_rds_stack && var.enable_rds_proxy ? 1 : 0

  name                   = "db-analytics-rds-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids         = [aws_subnet.application_private.id, aws_subnet.application_private_b.id]
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = local.rds_proxy_secret_arn
    iam_auth    = "DISABLED"
  }

  tags = {
    Name = "db-analytics-rds-proxy"
  }

  depends_on = [aws_iam_role_policy.rds_proxy_secret_access]
}

resource "aws_db_proxy_default_target_group" "rds" {
  count = var.enable_rds_stack && var.enable_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.rds[0].name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 80
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "rds_writer" {
  count = var.enable_rds_stack && var.enable_rds_proxy ? 1 : 0

  db_proxy_name          = aws_db_proxy.rds[0].name
  target_group_name      = aws_db_proxy_default_target_group.rds[0].name
  db_instance_identifier = local.rds_primary_identifier
}

resource "aws_vpc_security_group_ingress_rule" "database_from_application_direct" {
  count = var.enable_rds_stack && !var.enable_rds_proxy ? 1 : 0

  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Direct database access for the approved no-proxy learning configuration."
}

resource "aws_vpc_security_group_egress_rule" "application_to_database_direct" {
  count = var.enable_rds_stack && !var.enable_rds_proxy ? 1 : 0

  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow application-to-RDS traffic only when RDS Proxy is disabled."
}

resource "aws_security_group" "aurora_database" {
  count = var.enable_aurora_stack ? 1 : 0

  name                   = "db-analytics-aurora-database-sg"
  description            = "Aurora PostgreSQL accepts traffic only from the application tier."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-aurora-database-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_application" {
  count = var.enable_aurora_stack ? 1 : 0

  security_group_id            = aws_security_group.aurora_database[0].id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL traffic from application tier to Aurora PostgreSQL."
}

resource "aws_vpc_security_group_egress_rule" "application_to_aurora" {
  count = var.enable_aurora_stack ? 1 : 0

  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.aurora_database[0].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow application traffic to Aurora PostgreSQL only."
}

resource "aws_rds_cluster" "aurora" {
  count = var.enable_aurora_stack ? 1 : 0

  cluster_identifier          = var.aurora_cluster_identifier
  engine                      = "aurora-postgresql"
  database_name               = var.rds_db_name
  master_username             = var.rds_master_username
  manage_master_user_password = true
  port                        = 5432
  db_subnet_group_name        = aws_db_subnet_group.relational[0].name
  vpc_security_group_ids      = [aws_security_group.aurora_database[0].id]
  storage_encrypted           = true
  backup_retention_period     = 7
  preferred_backup_window     = "17:00-18:00"
  copy_tags_to_snapshot       = true
  deletion_protection         = false
  skip_final_snapshot         = true

  tags = {
    Name = var.aurora_cluster_identifier
  }
}

resource "aws_rds_cluster_instance" "aurora_writer" {
  count = var.enable_aurora_stack ? 1 : 0

  identifier                 = "${var.aurora_cluster_identifier}-writer"
  cluster_identifier         = aws_rds_cluster.aurora[0].id
  instance_class             = var.aurora_instance_class
  engine                     = "aurora-postgresql"
  availability_zone          = var.availability_zone_a
  db_subnet_group_name       = aws_db_subnet_group.relational[0].name
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.aurora_cluster_identifier}-writer"
    Role = "writer"
  }
}

resource "aws_rds_cluster_instance" "aurora_reader" {
  count = var.enable_aurora_stack && var.enable_aurora_reader ? 1 : 0

  identifier                 = "${var.aurora_cluster_identifier}-reader"
  cluster_identifier         = aws_rds_cluster.aurora[0].id
  instance_class             = var.aurora_instance_class
  engine                     = "aurora-postgresql"
  availability_zone          = var.availability_zone_b
  db_subnet_group_name       = aws_db_subnet_group.relational[0].name
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.aurora_cluster_identifier}-reader"
    Role = "reader"
  }
}
