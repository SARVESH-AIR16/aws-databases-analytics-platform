resource "aws_elasticache_subnet_group" "application" {
  count       = var.enable_elasticache_stack ? 1 : 0
  name        = "db-analytics-cache-subnets"
  description = "Private subnets for the optional Valkey cache"
  subnet_ids  = [aws_subnet.application_private.id, aws_subnet.application_private_b.id]

  tags = {
    Name   = "db-analytics-cache-subnets"
    Module = "caching"
  }
}

resource "aws_elasticache_replication_group" "valkey" {
  count = var.enable_elasticache_stack ? 1 : 0

  replication_group_id = "db-analytics-valkey"
  description          = "Optional encrypted Valkey cache for the portfolio application"
  engine               = "valkey"
  node_type            = var.elasticache_node_type
  num_cache_clusters   = var.elasticache_node_count
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.application[0].name
  security_group_ids   = [aws_security_group.cache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = length(var.elasticache_auth_token) >= 16 ? var.elasticache_auth_token : null
  automatic_failover_enabled = var.elasticache_multi_az_enabled && var.elasticache_node_count >= 2
  multi_az_enabled           = var.elasticache_multi_az_enabled && var.elasticache_node_count >= 2
  apply_immediately          = false

  lifecycle {
    precondition {
      condition     = length(var.elasticache_auth_token) >= 16
      error_message = "When enable_elasticache_stack=true, provide a 16-128 character AUTH token with TF_VAR_elasticache_auth_token or an untracked tfvars file."
    }
    precondition {
      condition     = !var.elasticache_multi_az_enabled || var.elasticache_node_count >= 2
      error_message = "Multi-AZ requires elasticache_node_count to be at least 2."
    }
  }

  tags = {
    Name   = "db-analytics-valkey"
    Module = "caching"
  }
}

resource "aws_dax_subnet_group" "orders" {
  count = var.enable_dax_stack ? 1 : 0

  name        = "db-analytics-dax-subnets"
  description = "Private subnets for the optional DynamoDB Accelerator cluster"
  subnet_ids  = [aws_subnet.application_private.id, aws_subnet.application_private_b.id]

  lifecycle {
    precondition {
      condition     = var.enable_dynamodb_stack
      error_message = "enable_dax_stack=true requires enable_dynamodb_stack=true because the DAX policy is scoped to the orders table."
    }
  }

}

resource "aws_iam_role" "dax_orders" {
  count = var.enable_dax_stack && var.enable_dynamodb_stack ? 1 : 0

  name = "db-analytics-dax-orders-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dax.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name   = "db-analytics-dax-orders-role"
    Module = "caching"
  }
}

resource "aws_iam_role_policy" "dax_orders" {
  count = var.enable_dax_stack && var.enable_dynamodb_stack ? 1 : 0

  name = "db-analytics-dax-orders-access"
  role = aws_iam_role.dax_orders[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ]
      Resource = [
        aws_dynamodb_table.orders[0].arn,
        "${aws_dynamodb_table.orders[0].arn}/index/*"
      ]
    }]
  })
}

resource "aws_dax_cluster" "orders" {
  count = var.enable_dax_stack && var.enable_dynamodb_stack ? 1 : 0

  cluster_name                     = "db-orders-dax"
  description                      = "Optional TLS-enabled DAX cluster for the DynamoDB orders table"
  iam_role_arn                     = aws_iam_role.dax_orders[0].arn
  node_type                        = var.dax_node_type
  replication_factor               = var.dax_replication_factor
  subnet_group_name                = aws_dax_subnet_group.orders[0].name
  security_group_ids               = [aws_security_group.dax.id]
  cluster_endpoint_encryption_type = "TLS"

  tags = {
    Name   = "db-orders-dax"
    Module = "caching"
  }
}
