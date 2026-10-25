output "analytics_s3_bucket_name" {
  description = "Name of the optional analytics data-lake bucket; null when the stack is disabled."
  value       = try(aws_s3_bucket.analytics_lake[0].bucket, null)
}

output "analytics_glue_database_name" {
  description = "Glue Catalog database name; null when the stack is disabled."
  value       = try(aws_glue_catalog_database.analytics[0].name, null)
}

output "analytics_athena_workgroup_name" {
  description = "Athena workgroup name; null when the stack is disabled."
  value       = try(aws_athena_workgroup.analytics[0].name, null)
}

output "analytics_glue_crawler_name" {
  description = "Optional Glue crawler name; null when the crawler is disabled."
  value       = try(aws_glue_crawler.parquet[0].name, null)
}

output "analytics_redshift_cluster_identifier" {
  description = "Private optional Redshift cluster identifier; null when Redshift is disabled."
  value       = try(aws_redshift_cluster.analytics[0].cluster_identifier, null)
}

output "analytics_redshift_endpoint" {
  description = "Private optional Redshift endpoint; null when Redshift is disabled."
  value       = try(aws_redshift_cluster.analytics[0].endpoint, null)
}
