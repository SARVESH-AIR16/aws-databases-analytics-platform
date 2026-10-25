resource "aws_dms_replication_task" "orders_full_load" {
  count = local.dms_resources_enabled ? 1 : 0

  replication_task_id      = "db-analytics-orders-full-load"
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.full_load[0].replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.postgres_source[0].endpoint_arn
  target_endpoint_arn      = aws_dms_s3_endpoint.parquet_target[0].endpoint_arn

  # Narrow, deterministic selection: only public.orders is included.
  table_mappings = jsonencode({
    rules = [{
      "rule-type" = "selection"
      "rule-id"   = "1"
      "rule-name" = "include-public-orders"
      "object-locator" = {
        "schema-name" = "public"
        "table-name"  = "orders"
      }
      "rule-action" = "include"
    }]
  })

  # Creating the task does not start it by default. Start only after the source
  # table exists and both endpoint connections have been tested.
  start_replication_task = var.enable_dms_task_start

  tags = {
    Name   = "db-analytics-orders-full-load"
    Module = "migration"
  }

  depends_on = [
    terraform_data.dms_prerequisite_guard,
    terraform_data.dms_task_start_guard,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs,
    aws_iam_role_policy.dms_s3_access
  ]
}
