# Security groups are defined separately from their rules so every rule has
# a unique Terraform resource and can be reviewed independently.
# No inbound SSH rule is created for the bastion until admin_cidr is set.

resource "aws_security_group" "bastion" {
  name                   = "db-analytics-bastion-sg"
  description            = "Controlled administration entry point; no SSH ingress unless admin_cidr is configured."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-bastion-sg"
  }
}

resource "aws_security_group" "application" {
  name                   = "db-analytics-application-sg"
  description            = "Application tier; administrative SSH is accepted only from the bastion security group."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-application-sg"
  }
}

resource "aws_security_group" "rds_proxy" {
  name                   = "db-analytics-rds-proxy-sg"
  description            = "Database proxy tier; accepts database traffic only from the application security group."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-rds-proxy-sg"
  }
}

resource "aws_security_group" "database" {
  name                   = "db-analytics-database-sg"
  description            = "Database tier; accepts the configured database port only from the RDS Proxy security group."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-database-sg"
  }
}

resource "aws_security_group" "cache" {
  name                   = "db-analytics-cache-sg"
  description            = "Cache tier; accepts Redis-compatible traffic only from the application security group."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-cache-sg"
  }
}

resource "aws_security_group" "dax" {
  name                   = "db-analytics-dax-sg"
  description            = "DAX tier; accepts DAX client ports only from the application security group."
  vpc_id                 = aws_vpc.application.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-dax-sg"
  }
}

resource "aws_security_group" "analytics_worker" {
  name                   = "db-analytics-worker-sg"
  description            = "Analytics worker tier; no inbound rules by default, S3 HTTPS egress only."
  vpc_id                 = aws_vpc.analytics.id
  revoke_rules_on_delete = true

  tags = {
    Name = "db-analytics-worker-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_from_admin" {
  count             = var.admin_cidr == "" ? 0 : 1
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH from the explicitly configured trusted administrator CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "application_ssh_from_bastion" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH from the bastion security group only"
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_application" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "Database client traffic from the application tier"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_rds_proxy" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "Database traffic from RDS Proxy only"
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_application" {
  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Redis-compatible cache traffic from the application tier"
}

resource "aws_vpc_security_group_ingress_rule" "dax_plain_from_application" {
  security_group_id            = aws_security_group.dax.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 8111
  to_port                      = 8111
  ip_protocol                  = "tcp"
  description                  = "DAX client port from the application tier"
}

resource "aws_vpc_security_group_ingress_rule" "dax_tls_from_application" {
  security_group_id            = aws_security_group.dax.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 9111
  to_port                      = 9111
  ip_protocol                  = "tcp"
  description                  = "DAX TLS client port from the application tier"
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh_to_application" {
  security_group_id            = aws_security_group.bastion.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Allow the bastion to initiate SSH to the application tier"
}

resource "aws_vpc_security_group_egress_rule" "application_to_rds_proxy" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "Application database sessions through RDS Proxy"
}

resource "aws_vpc_security_group_egress_rule" "application_to_cache" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.cache.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Application requests to cache"
}

resource "aws_vpc_security_group_egress_rule" "application_to_dax_plain" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.dax.id
  from_port                    = 8111
  to_port                      = 8111
  ip_protocol                  = "tcp"
  description                  = "Application requests to DAX client port"
}

resource "aws_vpc_security_group_egress_rule" "application_to_dax_tls" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.dax.id
  from_port                    = 9111
  to_port                      = 9111
  ip_protocol                  = "tcp"
  description                  = "Application requests to DAX TLS client port"
}

resource "aws_vpc_security_group_egress_rule" "application_to_s3_https" {
  security_group_id = aws_security_group.application.id
  prefix_list_id    = aws_vpc_endpoint.s3_application.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS to S3 using the gateway endpoint prefix list"
}

resource "aws_vpc_security_group_egress_rule" "application_to_dynamodb_https" {
  security_group_id = aws_security_group.application.id
  prefix_list_id    = aws_vpc_endpoint.dynamodb_application.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS to DynamoDB using the gateway endpoint prefix list"
}

resource "aws_vpc_security_group_egress_rule" "rds_proxy_to_database" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "RDS Proxy backend connections to database"
}

resource "aws_vpc_security_group_egress_rule" "dax_to_dynamodb_https" {
  security_group_id = aws_security_group.dax.id
  prefix_list_id    = aws_vpc_endpoint.dynamodb_application.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "DAX service access to DynamoDB through the gateway endpoint"
}

resource "aws_vpc_security_group_egress_rule" "analytics_worker_to_s3_https" {
  security_group_id = aws_security_group.analytics_worker.id
  prefix_list_id    = aws_vpc_endpoint.s3_analytics.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS to S3 using the analytics VPC gateway endpoint"
}
