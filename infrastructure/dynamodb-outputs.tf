output "dynamodb_orders_table_name" {
  description = "Name of the optional orders table; null when the DynamoDB stack is disabled."
  value       = try(aws_dynamodb_table.orders[0].name, null)
}

output "dynamodb_orders_table_arn" {
  description = "ARN of the optional orders table; null when the DynamoDB stack is disabled."
  value       = try(aws_dynamodb_table.orders[0].arn, null)
}

output "dynamodb_orders_stream_arn" {
  description = "Stream ARN when the optional DynamoDB table and Streams are enabled; otherwise null."
  value       = try(aws_dynamodb_table.orders[0].stream_arn, null)
}

output "dynamodb_app_role_arn" {
  description = "ARN of the optional least-privilege application role; null when the DynamoDB stack is disabled."
  value       = try(aws_iam_role.dynamodb_app[0].arn, null)
}

output "dynamodb_app_instance_profile_name" {
  description = "Instance profile name for future application compute; null when the DynamoDB stack is disabled."
  value       = try(aws_iam_instance_profile.dynamodb_app[0].name, null)
}
