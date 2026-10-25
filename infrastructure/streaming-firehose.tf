# Optional Kinesis Data Streams -> Amazon Data Firehose -> Module 6 S3 data lake.
resource "aws_kinesis_firehose_delivery_stream" "orders_to_s3" {
  count = var.enable_firehose_delivery ? 1 : 0

  name        = "db-analytics-orders-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.orders[0].arn
    role_arn           = aws_iam_role.firehose_delivery[0].arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery[0].arn
    bucket_arn = aws_s3_bucket.analytics_lake[0].arn

    prefix              = "data/streaming/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "data/streaming-errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.firehose_buffering_size_mb
    buffering_interval = var.firehose_buffering_interval_seconds
    compression_format = "GZIP"
  }

  tags = {
    Name   = "db-analytics-orders-firehose"
    Module = "streaming"
  }

  depends_on = [aws_iam_role_policy.firehose_delivery]
}
