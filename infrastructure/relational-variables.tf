variable "enable_rds_stack" {
  description = "Create the optional RDS PostgreSQL stack. Keep false until pricing and deployment are approved."
  type        = bool
  default     = false
}

variable "rds_instance_identifier" {
  description = "RDS PostgreSQL identifier."
  type        = string
  default     = "db-analytics-postgres"
}

variable "rds_instance_class" {
  description = "RDS instance class; pricing varies by Region and class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "portfolio"
}

variable "rds_master_username" {
  description = "Master database username; do not use this account for application traffic in a production design."
  type        = string
  default     = "portfolio_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.rds_master_username)) && lower(var.rds_master_username) != "postgres"
    error_message = "Use a valid PostgreSQL master username other than postgres."
  }
}

variable "rds_manage_master_user_password" {
  description = "Let RDS generate and rotate the master password in Secrets Manager. This cannot be used when creating a PostgreSQL read replica."
  type        = bool
  default     = true
}

variable "rds_master_password" {
  description = "Only required when RDS-managed password is disabled (for example, to enable a PostgreSQL read replica). Local Terraform state then contains sensitive credential data and must be protected."
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_multi_az" {
  description = "Enable the RDS Multi-AZ standby deployment. This materially increases cost."
  type        = bool
  default     = false
}

variable "enable_rds_read_replica" {
  description = "Create a separate RDS PostgreSQL read replica. This adds ongoing cost. Requires rds_manage_master_user_password=false."
  type        = bool
  default     = false
}

variable "enable_rds_proxy" {
  description = "Create RDS Proxy for the RDS PostgreSQL writer. RDS Proxy has ongoing charges."
  type        = bool
  default     = false
}

variable "enable_aurora_stack" {
  description = "Create the optional Aurora PostgreSQL cluster. Keep false until pricing and deployment are approved."
  type        = bool
  default     = false
}

variable "aurora_cluster_identifier" {
  description = "Aurora PostgreSQL cluster identifier."
  type        = string
  default     = "db-analytics-aurora-pg"
}

variable "aurora_instance_class" {
  description = "Aurora PostgreSQL DB instance class. Provisioned instances have ongoing compute charges."
  type        = string
  default     = "db.t4g.medium"
}

variable "enable_aurora_reader" {
  description = "Add an Aurora reader instance to the cluster for read scaling and reader-endpoint demonstrations. This adds ongoing cost."
  type        = bool
  default     = false
}
