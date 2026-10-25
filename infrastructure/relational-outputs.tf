output "rds_primary_endpoint" {
  description = "Private DNS endpoint for the optional RDS PostgreSQL primary; null when disabled."
  value       = try(aws_db_instance.primary[0].address, null)
}

output "rds_read_replica_endpoint" {
  description = "Private DNS endpoint for the optional RDS PostgreSQL read replica; null when disabled."
  value       = try(aws_db_instance.read_replica[0].address, null)
}

output "rds_proxy_endpoint" {
  description = "Private endpoint for the optional RDS Proxy; null when disabled."
  value       = try(aws_db_proxy.rds[0].endpoint, null)
}

output "aurora_writer_endpoint" {
  description = "Private writer endpoint for optional Aurora PostgreSQL; null when disabled."
  value       = try(aws_rds_cluster.aurora[0].endpoint, null)
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint; null when Aurora is disabled."
  value       = try(aws_rds_cluster.aurora[0].reader_endpoint, null)
}
