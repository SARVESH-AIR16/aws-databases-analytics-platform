output "application_vpc_id" {
  value = aws_vpc.application.id
}

output "analytics_vpc_id" {
  value = aws_vpc.analytics.id
}

output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.application_analytics.id
}
