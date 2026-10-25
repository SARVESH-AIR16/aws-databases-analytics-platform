variable "aws_region" {
  description = "AWS region for the project."
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone_a" {
  description = "First available Availability Zone."
  type        = string
  default     = "ap-south-1a"
}

variable "availability_zone_b" {
  description = "Second available Availability Zone."
  type        = string
  default     = "ap-south-1b"
}

variable "admin_cidr" {
  description = "Optional trusted IPv4 CIDR allowed to SSH to a future bastion. Leave empty to create no SSH ingress rule. Never use 0.0.0.0/0."
  type        = string
  default     = ""

  validation {
    condition     = var.admin_cidr == "" || can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid IPv4 CIDR, or an empty string."
  }
}

variable "database_port" {
  description = "Port for the planned relational database engine: PostgreSQL/Aurora PostgreSQL (5432) or MySQL/Aurora MySQL (3306)."
  type        = number
  default     = 5432

  validation {
    condition     = contains([3306, 5432], var.database_port)
    error_message = "database_port must be 5432 (PostgreSQL) or 3306 (MySQL)."
  }
}

variable "vpc1_cidr" {
  description = "Application VPC IPv4 range."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc1_public_subnet_cidr" {
  description = "Application VPC public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc1_private_subnet_cidr" {
  description = "First application private subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "vpc1_private_subnet_b_cidr" {
  description = "Second application private subnet."
  type        = string
  default     = "10.0.3.0/24"
}

variable "vpc2_cidr" {
  description = "Analytics VPC IPv4 range."
  type        = string
  default     = "10.1.0.0/16"
}

variable "vpc2_private_subnet_cidr" {
  description = "First analytics private subnet."
  type        = string
  default     = "10.1.1.0/24"
}

variable "vpc2_private_subnet_b_cidr" {
  description = "Second analytics private subnet."
  type        = string
  default     = "10.1.2.0/24"
}
