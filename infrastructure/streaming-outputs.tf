output "kinesis_orders_stream_name" {
  description = "Optional Kinesis order event stream name; null when disabled."
  value       = try(aws_kinesis_stream.orders[0].name, null)
}

output "kinesis_orders_stream_arn" {
  description = "Optional Kinesis order event stream ARN; null when disabled."
  value       = try(aws_kinesis_stream.orders[0].arn, null)
}

output "kinesis_producer_policy_json" {
  description = "Least-privilege policy template for a future producer role: stream metadata, PutRecord/PutRecords, and KMS data-key generation restricted to this stream. Null when Kinesis is disabled; not attached to an IAM identity."
  value       = try(data.aws_iam_policy_document.kinesis_producer_access[0].json, null)
}

output "firehose_orders_delivery_name" {
  description = "Optional Firehose S3 delivery stream name; null when disabled."
  value       = try(aws_kinesis_firehose_delivery_stream.orders_to_s3[0].name, null)
}

output "firehose_orders_delivery_arn" {
  description = "Optional Firehose S3 delivery stream ARN; null when disabled."
  value       = try(aws_kinesis_firehose_delivery_stream.orders_to_s3[0].arn, null)
}
