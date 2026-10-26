#!/usr/bin/env python3
"""Regression checks for the single canonical bastion admin SSH rule."""
from pathlib import Path
import re
import sys

sg_text = Path("infrastructure/security-groups.tf").read_text()
hosts_text = Path("infrastructure/compute-hosts.tf").read_text()
header = 'resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_from_admin" {'

assert sg_text.count(header) == 1, "Expected exactly one canonical bastion SSH rule in security-groups.tf"
assert hosts_text.count(header) == 0, "Duplicate bastion SSH rule found in compute-hosts.tf"
start = sg_text.index(header)
opening = sg_text.index("{", start)
depth = 0
end = None
for i in range(opening, len(sg_text)):
    if sg_text[i] == "{":
        depth += 1
    elif sg_text[i] == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
assert end is not None, "Could not parse canonical bastion SSH ingress block"
block = sg_text[start:end]
checks = {
    "administrator IPv4 CIDR variable": r"cidr_ipv4\s*=\s*var\.admin_cidr",
    "SSH port 22 source": r"from_port\s*=\s*22",
    "SSH port 22 destination": r"to_port\s*=\s*22",
    "TCP protocol": r'ip_protocol\s*=\s*"tcp"',
}
for label, pattern in checks.items():
    assert re.search(pattern, block), f"Missing or invalid {label} restriction"
    print(f"PASS: Bastion ingress has {label} restriction")
print("PASS: Exactly one canonical admin SSH rule exists; no duplicate in compute-hosts.tf")
