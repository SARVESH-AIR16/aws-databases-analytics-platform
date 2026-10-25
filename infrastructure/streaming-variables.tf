variable "enable_kinesis_stream" {
  description = "Create the optional encrypted, provisioned Kinesis Data Stream. Keep false until regional pricing is reviewed."
  type        = bool
  default     = false
}

variable "kinesis_shard_count" {
  description = "Provisioned shards for the demo stream. Every shard can incur ongoing hourly charges while the stream exists."
  type        = number
  default     = 1
  validation {
    condition     = var.kinesis_shard_count >= 1 && var.kinesis_shard_count <= 4 && floor(var.kinesis_shard_count) == var.kinesis_shard_count
    error_message = "kinesis_shard_count must be a whole number from 1 through 4."
  }
}

variable "kinesis_retention_hours" {
  description = "Hours to retain stream records; 24 hours is the minimum and lowest-retention demo default."
  type        = number
  default     = 24
  validation {
    condition     = var.kinesis_retention_hours >= 24 && var.kinesis_retention_hours <= 168 && floor(var.kinesis_retention_hours) == var.kinesis_retention_hours
    error_message = "kinesis_retention_hours must be a whole number from 24 through 168."
  }
}

variable "enable_firehose_delivery" {
  description = "Create the optional Firehose consumer that writes compressed stream data into the Module 6 analytics S3 bucket."
  type        = bool
  default     = false
  validation {
    condition     = !var.enable_firehose_delivery || var.enable_kinesis_stream
    error_message = "enable_firehose_delivery=true requires enable_kinesis_stream=true."
  }
  validation {
    condition     = !var.enable_firehose_delivery || var.enable_analytics_stack
    error_message = "enable_firehose_delivery=true requires enable_analytics_stack=true because its destination is the analytics S3 bucket."
  }
}

variable "firehose_buffering_size_mb" {
  description = "S3 destination buffer size in MiB. Larger batches reduce tiny-file overhead but add delivery latency."
  type        = number
  default     = 5
  validation {
    condition     = var.firehose_buffering_size_mb >= 1 && var.firehose_buffering_size_mb <= 128 && floor(var.firehose_buffering_size_mb) == var.firehose_buffering_size_mb
    error_message = "firehose_buffering_size_mb must be a whole number from 1 through 128."
  }
}

variable "firehose_buffering_interval_seconds" {
  description = "S3 delivery buffer interval in seconds; Firehose supports 60 through 900 seconds."
  type        = number
  default     = 300
  validation {
    condition     = var.firehose_buffering_interval_seconds >= 60 && var.firehose_buffering_interval_seconds <= 900 && floor(var.firehose_buffering_interval_seconds) == var.firehose_buffering_interval_seconds
    error_message = "firehose_buffering_interval_seconds must be a whole number from 60 through 900."
  }
}
