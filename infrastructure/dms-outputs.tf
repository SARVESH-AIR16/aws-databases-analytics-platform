output "dms_replication_instance_arn" {
  description = "Private DMS replication instance ARN; null when DMS is not ready/enabled."
  value       = try(aws_dms_replication_instance.full_load[0].replication_instance_arn, null)
}

output "dms_source_endpoint_arn" {
  description = "RDS PostgreSQL source endpoint ARN; null when DMS is disabled."
  value       = try(aws_dms_endpoint.postgres_source[0].endpoint_arn, null)
}

output "dms_s3_target_endpoint_arn" {
  description = "S3 Parquet target endpoint ARN; null when DMS is disabled."
  value       = try(aws_dms_s3_endpoint.parquet_target[0].endpoint_arn, null)
}

output "dms_orders_task_arn" {
  description = "Full-load task ARN for public.orders; null when DMS is disabled."
  value       = try(aws_dms_replication_task.orders_full_load[0].replication_task_arn, null)
}

output "dms_s3_target_prefix" {
  description = "S3 prefix where the DMS full-load writes Parquet objects."
  value       = try("s3://${aws_s3_bucket.analytics_lake[0].bucket}/data/dms-migration/", null)
}
