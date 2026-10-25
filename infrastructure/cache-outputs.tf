output "elasticache_primary_endpoint" {
  description = "Primary endpoint for the optional Valkey replication group; null when disabled."
  value       = try(aws_elasticache_replication_group.valkey[0].primary_endpoint_address, null)
}

output "elasticache_reader_endpoint" {
  description = "Reader endpoint for the optional Valkey replication group; null when disabled."
  value       = try(aws_elasticache_replication_group.valkey[0].reader_endpoint_address, null)
}

output "dax_cluster_endpoint" {
  description = "TLS-enabled DAX endpoint; null when DAX is disabled."
  value       = try(aws_dax_cluster.orders[0].cluster_address, null)
}
