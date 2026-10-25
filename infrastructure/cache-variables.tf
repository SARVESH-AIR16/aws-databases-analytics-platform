variable "enable_elasticache_stack" {
  description = "Create the optional Valkey replication group. Keep false until pricing is reviewed and deployment is approved."
  type        = bool
  default     = false
}

variable "elasticache_node_type" {
  description = "ElastiCache node type; verify current ap-south-1 pricing before enabling."
  type        = string
  default     = "cache.t4g.micro"
}

variable "elasticache_node_count" {
  description = "Total nodes in the non-cluster-mode ElastiCache replication group. One node is the least expensive non-HA configuration."
  type        = number
  default     = 1
  validation {
    condition     = var.elasticache_node_count >= 1 && var.elasticache_node_count <= 6 && floor(var.elasticache_node_count) == var.elasticache_node_count
    error_message = "elasticache_node_count must be a whole number from 1 through 6."
  }
}

variable "elasticache_multi_az_enabled" {
  description = "Enable Multi-AZ/failover only when at least two cache nodes are configured; this increases ongoing cost."
  type        = bool
  default     = false
}

variable "elasticache_auth_token" {
  description = "Sensitive Valkey AUTH token. Supply through TF_VAR_elasticache_auth_token or an untracked tfvars file; never commit it. Required when ElastiCache is enabled."
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition     = var.elasticache_auth_token == "" || (length(var.elasticache_auth_token) >= 16 && length(var.elasticache_auth_token) <= 128)
    error_message = "elasticache_auth_token must be empty or between 16 and 128 characters."
  }
}

variable "enable_dax_stack" {
  description = "Create the optional TLS-enabled DAX cluster; also requires the optional DynamoDB stack. DAX nodes can incur ongoing charges."
  type        = bool
  default     = false
}

variable "dax_node_type" {
  description = "DAX node type; verify current ap-south-1 pricing and availability before enabling."
  type        = string
  default     = "dax.t3.small"
}

variable "dax_replication_factor" {
  description = "DAX cluster node count. One node is not highly available; larger values increase cost."
  type        = number
  default     = 1
  validation {
    condition     = var.dax_replication_factor >= 1 && var.dax_replication_factor <= 10 && floor(var.dax_replication_factor) == var.dax_replication_factor
    error_message = "dax_replication_factor must be a whole number from 1 through 10."
  }
}
