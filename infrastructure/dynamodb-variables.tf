variable "enable_dynamodb_stack" {
  description = "Create the optional DynamoDB orders table and least-privilege application role. Keep false until deployment and cost review are approved."
  type        = bool
  default     = false
}

variable "dynamodb_orders_table_name" {
  description = "DynamoDB orders table name."
  type        = string
  default     = "db-analytics-orders"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.dynamodb_orders_table_name))
    error_message = "DynamoDB table names must be 3-255 characters and contain only letters, digits, underscores, hyphens, or periods."
  }
}

variable "dynamodb_max_read_request_units" {
  description = "Optional best-effort maximum on-demand read request units per second; exceeding it can throttle requests. Not a hard spending cap."
  type        = number
  default     = 100

  validation {
    condition     = var.dynamodb_max_read_request_units >= 1 && floor(var.dynamodb_max_read_request_units) == var.dynamodb_max_read_request_units
    error_message = "The DynamoDB on-demand read maximum must be a positive integer."
  }
}

variable "dynamodb_max_write_request_units" {
  description = "Optional best-effort maximum on-demand write request units per second; exceeding it can throttle requests. Not a hard spending cap."
  type        = number
  default     = 100

  validation {
    condition     = var.dynamodb_max_write_request_units >= 1 && floor(var.dynamodb_max_write_request_units) == var.dynamodb_max_write_request_units
    error_message = "The DynamoDB on-demand write maximum must be a positive integer."
  }
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB point-in-time recovery. This can add backup charges; keep false until reviewed."
  type        = bool
  default     = false
}

variable "dynamodb_ttl_enabled" {
  description = "Enable expiry-based cleanup using the expires_at epoch-seconds attribute."
  type        = bool
  default     = false
}

variable "dynamodb_enable_streams" {
  description = "Enable DynamoDB Streams for a future streaming module. Keep false until the integration is designed and cost-reviewed."
  type        = bool
  default     = false
}

variable "dynamodb_deletion_protection" {
  description = "Enable table deletion protection after deployment acceptance. False by default to permit deliberate cleanup of this learning resource."
  type        = bool
  default     = false
}
