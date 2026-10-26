variable "enable_compute_hosts" {
  description = "Create the bastion/admin and private application EC2 hosts for the temporary portfolio demo. Creates billable instances; keep false until deployment is approved."
  type        = bool
  default     = false
}

variable "enable_analytics_worker" {
  description = "Create the optional private analytics worker EC2 host. Requires enable_compute_hosts and enable_analytics_stack."
  type        = bool
  default     = false
  validation {
    condition     = !var.enable_analytics_worker || var.enable_compute_hosts
    error_message = "enable_analytics_worker=true requires enable_compute_hosts=true."
  }
  validation {
    condition     = !var.enable_analytics_worker || var.enable_analytics_stack
    error_message = "enable_analytics_worker=true requires enable_analytics_stack=true."
  }
}

variable "compute_instance_type" {
  description = "Small x86_64 instance type used by the temporary demo hosts. Verify current Mumbai availability/pricing before enabling."
  type        = string
  default     = "t3.micro"
  validation {
    condition     = contains(["t3.micro", "t3.small"], var.compute_instance_type)
    error_message = "compute_instance_type must be t3.micro or t3.small for this demo configuration."
  }
}

variable "compute_ssh_public_key" {
  description = "Public half of a locally generated SSH key, used to access the bastion and private hosts. Never supply or commit the private key."
  type        = string
  default     = ""
  validation {
    condition     = var.compute_ssh_public_key == "" || startswith(trimspace(var.compute_ssh_public_key), "ssh-ed25519 ") || startswith(trimspace(var.compute_ssh_public_key), "ssh-rsa ")
    error_message = "compute_ssh_public_key must be an OpenSSH public key (ssh-ed25519 or ssh-rsa), or empty while hosts are disabled."
  }
}

variable "compute_root_volume_gib" {
  description = "Encrypted gp3 root volume size per temporary EC2 host."
  type        = number
  default     = 8
  validation {
    condition     = var.compute_root_volume_gib >= 8 && var.compute_root_volume_gib <= 30 && floor(var.compute_root_volume_gib) == var.compute_root_volume_gib
    error_message = "compute_root_volume_gib must be a whole number from 8 through 30."
  }
}
