resource "aws_dynamodb_table" "orders" {
  count = var.enable_dynamodb_stack ? 1 : 0

  name         = var.dynamodb_orders_table_name
  billing_mode = "PAY_PER_REQUEST"
  table_class  = "STANDARD"
  hash_key     = "customer_id"
  range_key    = "order_id"

  deletion_protection_enabled = var.dynamodb_deletion_protection
  stream_enabled              = var.dynamodb_enable_streams
  stream_view_type            = var.dynamodb_enable_streams ? "NEW_AND_OLD_IMAGES" : null

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name               = "status-created-index"
    hash_key           = "status"
    range_key          = "created_at"
    projection_type    = "INCLUDE"
    non_key_attributes = ["order_total", "currency"]

    on_demand_throughput {
      max_read_request_units  = var.dynamodb_max_read_request_units
      max_write_request_units = var.dynamodb_max_write_request_units
    }
  }

  on_demand_throughput {
    max_read_request_units  = var.dynamodb_max_read_request_units
    max_write_request_units = var.dynamodb_max_write_request_units
  }

  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  dynamic "ttl" {
    for_each = var.dynamodb_ttl_enabled ? [true] : []
    content {
      attribute_name = "expires_at"
      enabled        = true
    }
  }

  tags = {
    Name        = var.dynamodb_orders_table_name
    DataDomain  = "orders"
    Module      = "dynamodb"
    Environment = "portfolio"
  }
}

# This EC2-trusted role is prepared for the future application tier. No EC2
# instance is created by this module; attach the instance profile when that
# application component is implemented and reviewed.
resource "aws_iam_role" "dynamodb_app" {
  count = var.enable_dynamodb_stack ? 1 : 0

  name = "db-analytics-dynamodb-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "db-analytics-dynamodb-app-role"
  }
}

resource "aws_iam_role_policy" "dynamodb_orders_access" {
  count = var.enable_dynamodb_stack ? 1 : 0

  name = "db-analytics-orders-table-access"
  role = aws_iam_role.dynamodb_app[0].id

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
        "dynamodb:UpdateItem"
      ]
      Resource = [
        aws_dynamodb_table.orders[0].arn,
        "${aws_dynamodb_table.orders[0].arn}/index/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "dynamodb_app" {
  count = var.enable_dynamodb_stack ? 1 : 0

  name = "db-analytics-dynamodb-app-profile"
  role = aws_iam_role.dynamodb_app[0].name

  tags = {
    Name = "db-analytics-dynamodb-app-profile"
  }
}
