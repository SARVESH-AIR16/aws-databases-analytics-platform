# Gateway endpoints avoid NAT for S3/DynamoDB access from private route tables.
# AWS does not charge an additional endpoint-hour or endpoint-processing fee
# for S3 and DynamoDB gateway endpoints; service requests and other AWS usage
# remain subject to their normal pricing and permissions.

resource "aws_vpc_endpoint" "s3_application" {
  vpc_id            = aws_vpc.application.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.application_private.id]

  tags = {
    Name = "application-s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb_application" {
  vpc_id            = aws_vpc.application.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.application_private.id]

  tags = {
    Name = "application-dynamodb-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3_analytics" {
  vpc_id            = aws_vpc.analytics.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.analytics_private.id]

  tags = {
    Name = "analytics-s3-gateway-endpoint"
  }
}
