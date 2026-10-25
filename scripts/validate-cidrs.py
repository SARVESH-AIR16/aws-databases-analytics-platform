#!/usr/bin/env python3
import ipaddress
import sys

vpcs = {
    "vpc1": ipaddress.ip_network("10.0.0.0/16"),
    "vpc2": ipaddress.ip_network("10.1.0.0/16"),
}

subnets = {
    "vpc1_public": ("vpc1", ipaddress.ip_network("10.0.1.0/24")),
    "vpc1_private_a": ("vpc1", ipaddress.ip_network("10.0.2.0/24")),
    "vpc1_private_b": ("vpc1", ipaddress.ip_network("10.0.3.0/24")),
    "vpc2_private_a": ("vpc2", ipaddress.ip_network("10.1.1.0/24")),
    "vpc2_private_b": ("vpc2", ipaddress.ip_network("10.1.2.0/24")),
}

errors = []

vpc_items = list(vpcs.items())
for i, (name_a, net_a) in enumerate(vpc_items):
    for name_b, net_b in vpc_items[i + 1:]:
        if net_a.overlaps(net_b):
            errors.append(f"{name_a} ({net_a}) overlaps {name_b} ({net_b})")

subnet_items = list(subnets.items())
for name, (parent_name, network) in subnet_items:
    if not network.subnet_of(vpcs[parent_name]):
        errors.append(f"{name} ({network}) is outside {parent_name} ({vpcs[parent_name]})")

for i, (name_a, (_, net_a)) in enumerate(subnet_items):
    for name_b, (_, net_b) in subnet_items[i + 1:]:
        if net_a.overlaps(net_b):
            errors.append(f"{name_a} ({net_a}) overlaps {name_b} ({net_b})")

for name, network in vpcs.items():
    print(f"{name:20} {network}")

for name, (_, network) in subnets.items():
    print(f"{name:20} {network}")

if errors:
    print("\nFAIL: CIDR validation found problems:", file=sys.stderr)
    for error in errors:
        print(f" - {error}", file=sys.stderr)
    sys.exit(1)

print("\nPASS: VPC ranges do not overlap; all subnets are contained and non-overlapping.")
print("NOTE: Check these ranges against any VPN, home, or corporate networks before deployment.")
