variable "enable_analytics_stack" {
  description = "Create the optional S3 data lake, Glue Catalog database, and Athena workgroup."
  type        = bool
  default     = false
}

variable "enable_athena_workgroup" {
  description = "Create the optional Athena workgroup when enabled for the selected account plan."
  type        = bool
  default     = true
}

variable "enable_glue_crawler" {
  description = "Create an optional on-demand Glue crawler for Parquet objects in the data lake."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_glue_crawler || var.enable_analytics_stack
    error_message = "enable_glue_crawler=true requires enable_analytics_stack=true."
  }
}

variable "enable_redshift_stack" {
  description = "Create an optional private single-node provisioned Amazon Redshift cluster. It incurs ongoing compute charges while running."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_redshift_stack || var.enable_analytics_stack
    error_message = "enable_redshift_stack=true requires enable_analytics_stack=true."
  }
}

variable "athena_bytes_scanned_cutoff_bytes" {
  description = "Maximum bytes scanned per query in the managed Athena workgroup."
  type        = number
  default     = 52428800 # 50 MiB

  validation {
    condition     = var.athena_bytes_scanned_cutoff_bytes >= 1048576
    error_message = "athena_bytes_scanned_cutoff_bytes must be at least 1 MiB."
  }
}

variable "redshift_node_type" {
  description = "Node type for the optional single-node Redshift demo cluster. Confirm current ap-south-1 availability and pricing before enabling."
  type        = string
  default     = "rg.large"

  validation {
    condition     = contains(["rg.large", "rg.xlarge"], var.redshift_node_type)
    error_message = "redshift_node_type must be rg.large or rg.xlarge. rg.large single-node requires the current P204-or-later maintenance track."
  }
}
