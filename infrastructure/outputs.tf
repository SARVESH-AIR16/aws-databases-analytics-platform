output "application_vpc_id" {
  description = "ID of the application VPC."
  value       = aws_vpc.application.id
}

output "analytics_vpc_id" {
  description = "ID of the analytics VPC."
  value       = aws_vpc.analytics.id
}

output "vpc_peering_connection_id" {
  description = "ID of the application-to-analytics VPC peering connection."
  value       = aws_vpc_peering_connection.application_analytics.id
}

output "application_security_group_ids" {
  description = "Security group IDs for the application VPC tiers. No EC2/database/cache resources are created by these groups alone."
  value = {
    bastion     = aws_security_group.bastion.id
    application = aws_security_group.application.id
    rds_proxy   = aws_security_group.rds_proxy.id
    database    = aws_security_group.database.id
    cache       = aws_security_group.cache.id
    dax         = aws_security_group.dax.id
  }
}

output "analytics_worker_security_group_id" {
  description = "Security group ID reserved for a future analytics worker."
  value       = aws_security_group.analytics_worker.id
}

output "gateway_endpoint_ids" {
  description = "Gateway endpoint IDs; endpoint access is still subject to IAM and resource policies."
  value = {
    application_s3       = aws_vpc_endpoint.s3_application.id
    application_dynamodb = aws_vpc_endpoint.dynamodb_application.id
    analytics_s3         = aws_vpc_endpoint.s3_analytics.id
  }
}
