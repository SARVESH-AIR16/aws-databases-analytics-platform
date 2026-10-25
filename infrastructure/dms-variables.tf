variable "enable_dms_stack" {
  description = "Create the optional AWS DMS full-load migration from private RDS PostgreSQL to the Module 6 analytics S3 lake. Keep false until costs and prerequisites are reviewed."
  type        = bool
  default     = false
}

variable "dms_replication_instance_class" {
  description = "AWS DMS replication instance class. Check current ap-south-1 availability and hourly pricing before enabling."
  type        = string
  default     = "dms.t3.micro"
  validation {
    condition     = contains(["dms.t3.micro", "dms.t3.small", "dms.t3.medium"], var.dms_replication_instance_class)
    error_message = "Choose a supported demo DMS class from dms.t3.micro, dms.t3.small, or dms.t3.medium and verify current regional availability before deployment."
  }
}

variable "dms_allocated_storage_gib" {
  description = "Small allocated storage for the optional DMS replication instance. DMS storage and instance-hours can incur charges."
  type        = number
  default     = 5
  validation {
    condition     = var.dms_allocated_storage_gib >= 5 && var.dms_allocated_storage_gib <= 50 && floor(var.dms_allocated_storage_gib) == var.dms_allocated_storage_gib
    error_message = "dms_allocated_storage_gib must be a whole number from 5 through 50 for this demo configuration."
  }
}

variable "dms_multi_az" {
  description = "Enable Multi-AZ for DMS only after an explicit availability and cost review."
  type        = bool
  default     = false
}

variable "enable_dms_task_start" {
  description = "Start the full-load task after its prerequisites are ready. Keep false until both endpoints are tested and public evidence capture is approved."
  type        = bool
  default     = false
}
