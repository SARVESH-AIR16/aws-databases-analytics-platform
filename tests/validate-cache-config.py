#!/usr/bin/env python3
"""Static guardrails for the optional ElastiCache and DAX module."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
INFRA = ROOT / "infrastructure"


def expect(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)
    print(f"PASS: {message}")


def main() -> int:
    variables = (INFRA / "cache-variables.tf").read_text()
    stack = (INFRA / "cache-stack.tf").read_text()
    sg = (INFRA / "security-groups.tf").read_text()
    expect(bool(re.search(r'variable\s+"enable_elasticache_stack"\s*\{[^}]*default\s*=\s*false', variables, re.S)), "ElastiCache disabled by default")
    expect(bool(re.search(r'variable\s+"enable_dax_stack"\s*\{[^}]*default\s*=\s*false', variables, re.S)), "DAX disabled by default")
    expect('engine               = "valkey"' in stack, "Valkey engine configured")
    expect("at_rest_encryption_enabled = true" in stack, "ElastiCache encryption at rest enabled")
    expect("transit_encryption_enabled = true" in stack, "ElastiCache TLS enabled")
    expect("auth_token                 =" in stack and "elasticache_auth_token" in variables, "AUTH token supplied as sensitive variable")
    expect("aws_subnet.application_private.id, aws_subnet.application_private_b.id" in stack, "Cache subnet groups use two private subnets")
    expect('cluster_endpoint_encryption_type = "TLS"' in stack, "DAX endpoint TLS enforced")
    expect("aws_dynamodb_table.orders[0].arn" in stack and '"${aws_dynamodb_table.orders[0].arn}/index/*"' in stack, "DAX IAM permissions scoped to orders table and its indexes")
    expect('"dax_plain_from_application"' not in sg and '"application_to_dax_plain"' not in sg, "Plaintext DAX port rules removed")
    expect('"dax_tls_from_application"' in sg and '"application_to_dax_tls"' in sg, "DAX TLS port rules retained")
    print("All cache static guardrails passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, AssertionError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
