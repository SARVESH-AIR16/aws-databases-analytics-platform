#!/usr/bin/env python3
"""Static guardrails and sample-data validation for Module 4."""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
variables = (ROOT / "infrastructure" / "dynamodb-variables.tf").read_text()
stack = (ROOT / "infrastructure" / "dynamodb-stack.tf").read_text()
outputs = (ROOT / "infrastructure" / "dynamodb-outputs.tf").read_text()

checks = {
    "DynamoDB stack disabled by default": 'variable "enable_dynamodb_stack"' in variables and 'default     = false' in variables.split('variable "enable_dynamodb_stack"', 1)[1].split('\n}', 1)[0],
    "Pay-per-request capacity mode": 'billing_mode = "PAY_PER_REQUEST"' in stack,
    "Maximum on-demand read and write throughput configured": stack.count("max_read_request_units") == 4 and stack.count("max_write_request_units") == 4,
    "PITR disabled by default": 'variable "dynamodb_point_in_time_recovery"' in variables and 'default     = false' in variables.split('variable "dynamodb_point_in_time_recovery"', 1)[1].split('\n}', 1)[0],
    "Streams disabled by default": 'variable "dynamodb_enable_streams"' in variables and 'default     = false' in variables.split('variable "dynamodb_enable_streams"', 1)[1].split('\n}', 1)[0],
    "Order table has customer/order composite key": 'hash_key     = "customer_id"' in stack and 'range_key    = "order_id"' in stack,
    "Status/created timestamp GSI configured": 'name               = "status-created-index"' in stack and 'hash_key           = "status"' in stack and 'range_key          = "created_at"' in stack,
    "App IAM policy scoped to table and indexes": 'aws_dynamodb_table.orders[0].arn' in stack and '"${aws_dynamodb_table.orders[0].arn}/index/*"' in stack,
    "IAM policy omits table Scan permission": '"dynamodb:Scan"' not in stack,
    "Outputs tolerate disabled stack": 'try(aws_dynamodb_table.orders[0].name, null)' in outputs,
}

failed = False
for label, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {label}")
    failed |= not passed

if failed:
    sys.exit(1)

run = subprocess.run(
    [sys.executable, str(ROOT / "scripts" / "dynamodb_demo.py"), "validate-sample"],
    check=False,
    capture_output=True,
    text=True,
)
print(run.stdout, end="")
if run.returncode:
    print(run.stderr, file=sys.stderr, end="")
    sys.exit(run.returncode)
print("PASS: DynamoDB static guardrails passed.")
