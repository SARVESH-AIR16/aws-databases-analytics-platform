resource "aws_dms_endpoint" "postgres_source" {
  count = local.dms_resources_enabled ? 1 : 0

  endpoint_id   = "db-analytics-postgres-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  database_name = var.rds_db_name
  server_name   = local.rds_primary_address
  port          = 5432
  username      = var.rds_master_username
  password      = var.rds_master_password
  ssl_mode      = "require"

  lifecycle {
    precondition {
      condition     = nonsensitive(length(var.rds_master_password)) >= 16
      error_message = "Provide a strong RDS password of at least 16 characters before enabling the DMS stack. The endpoint password is stored in Terraform state; protect the state."
    }
  }

  tags = {
    Name   = "db-analytics-postgres-source"
    Module = "migration"
  }

  depends_on = [terraform_data.dms_prerequisite_guard]
}

resource "aws_dms_s3_endpoint" "parquet_target" {
  count = local.dms_resources_enabled ? 1 : 0

  endpoint_id             = "db-analytics-dms-s3-target"
  endpoint_type           = "target"
  bucket_name             = aws_s3_bucket.analytics_lake[0].bucket
  bucket_folder           = "data/dms-migration"
  service_access_role_arn = aws_iam_role.dms_s3_access[0].arn
  data_format             = "parquet"
  encryption_mode         = "SSE_S3"
  expected_bucket_owner   = data.aws_caller_identity.dms[0].account_id

  tags = {
    Name   = "db-analytics-dms-s3-target"
    Module = "migration"
  }

  depends_on = [
    terraform_data.dms_prerequisite_guard,
    aws_iam_role_policy.dms_s3_access,
    aws_s3_bucket_server_side_encryption_configuration.analytics_lake
  ]
}
