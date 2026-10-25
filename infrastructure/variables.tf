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
