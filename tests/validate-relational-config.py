#!/usr/bin/env python3
"""Basic static guardrails for optional relational Terraform configuration."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
variables = (root / "infrastructure" / "relational-variables.tf").read_text()
stack = (root / "infrastructure" / "relational-stack.tf").read_text()

checks = {
    "RDS stack disabled by default": 'variable "enable_rds_stack"' in variables and 'default     = false' in variables.split('variable "enable_rds_stack"', 1)[1].split('\n}', 1)[0],
    "Aurora stack disabled by default": 'variable "enable_aurora_stack"' in variables and 'default     = false' in variables.split('variable "enable_aurora_stack"', 1)[1].split('\n}', 1)[0],
    "RDS primary is private": "publicly_accessible    = false" in stack,
    "RDS storage encryption enabled": "storage_encrypted     = true" in stack,
    "RDS-managed password/read-replica guardrail": "!(var.enable_rds_read_replica && var.rds_manage_master_user_password)" in stack,
    "RDS Proxy requires TLS": "require_tls            = true" in stack,
    "Private subnet group uses two AZ subnet resources": "aws_subnet.application_private.id, aws_subnet.application_private_b.id" in stack,
}

failed = False
for label, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {label}")
    failed |= not passed

if failed:
    sys.exit(1)
print("PASS: Relational configuration static guardrails passed.")
