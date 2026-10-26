#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
vars_tf = (ROOT / "infrastructure/compute-hosts-variables.tf").read_text()
hosts_tf = (ROOT / "infrastructure/compute-hosts.tf").read_text()
sg_tf = (ROOT / "infrastructure/security-groups.tf").read_text()

checks = {
    "Compute hosts disabled by default": 'variable "enable_compute_hosts"' in vars_tf and 'default     = false' in vars_tf.split('variable "enable_compute_hosts"', 1)[1].split('}', 1)[0],
    "Analytics worker disabled by default": 'variable "enable_analytics_worker"' in vars_tf and 'default     = false' in vars_tf.split('variable "enable_analytics_worker"', 1)[1].split('}', 1)[0],
    "Worker requires compute hosts and analytics bucket": 'enable_compute_hosts=true and enable_analytics_stack=true' in hosts_tf,
    "Bastion is in public subnet with explicit public IP": 'aws_subnet.application_public.id' in hosts_tf and bool(re.search(r'(?m)^\s*associate_public_ip_address\s*=\s*true\s*$', hosts_tf)),
    "Application host stays private": 'aws_subnet.application_private.id' in hosts_tf and len(re.findall(r'(?m)^\s*associate_public_ip_address\s*=\s*false\s*$', hosts_tf)) >= 2,
    "Analytics worker stays private": 'aws_subnet.analytics_private.id' in hosts_tf and len(re.findall(r'(?m)^\s*associate_public_ip_address\s*=\s*false\s*$', hosts_tf)) >= 2,
    "SSH key is provided as public key only": 'public_key = var.compute_ssh_public_key' in hosts_tf and 'private_key' not in hosts_tf,
    "Admin CIDR and key are required before host creation": 'var.admin_cidr' in hosts_tf and 'compute_ssh_public_key' in hosts_tf and '0.0.0.0/0' in hosts_tf,
    "EC2 uses encrypted gp3 roots": hosts_tf.count('volume_type           = "gp3"') == 3 and hosts_tf.count('encrypted             = true') == 3,
    "IMDSv2 required on all hosts": hosts_tf.count('http_tokens   = "required"') == 3,
    "AMI comes from AWS maintained AL2023 SSM parameter": '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64' in hosts_tf,
    "Analytics worker S3 object access limited to data prefix": '"${aws_s3_bucket.analytics_lake[0].arn}/data/*"' in hosts_tf and 's3:PutObject' in hosts_tf,
    "Worker SSH ingress is from bastion security group only": 'analytics_worker_ssh_from_bastion' in hosts_tf and 'referenced_security_group_id = aws_security_group.bastion.id' in hosts_tf,
    "No internet-wide SSH ingress is introduced": '0.0.0.0/0' not in sg_tf,
}
failed = []
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)
    if not ok:
        failed.append(name)
if failed:
    print(f"FAILED: {len(failed)} compute-host guardrail(s).")
    sys.exit(1)
print("PASS: compute-host static guardrails passed.")
