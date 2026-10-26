# Compute host layer (architecture foundation)

This layer fills the EC2 host roles shown in the architecture: a restricted administration bastion, a private application host, and an optional private analytics worker.

## Cost-safe defaults

- `enable_compute_hosts = false`
- `enable_analytics_worker = false`
- A bastion public IPv4 address is billable while allocated.
- EC2 instances and encrypted EBS root volumes are billable while provisioned. Terminate them after the reviewer window.
- The analytics worker requires both compute hosts and the analytics S3 stack.

## Access and security

Before enabling hosts, create an SSH key locally and set `compute_ssh_public_key` to its public half. Set `admin_cidr` to your trusted public IPv4 address with a `/32` mask. Never use `0.0.0.0/0` for SSH. Keep the private key local and out of Git.

The bastion sits in the public subnet; the application and analytics worker sit in private subnets. EC2 root volumes are encrypted gp3, and IMDSv2 is required. The app's demo HTTP service binds to loopback and should be viewed through an SSH tunnel rather than exposed to the Internet.

The analytics worker's role can list the data lake's `data/` prefix and read/write objects under `data/*`, but not other bucket prefixes.

## Local checks

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-compute-hosts-config.py
```

This module adds configuration only. It has not been deployed to AWS. Verify current Mumbai prices and inspect the Terraform plan before approving any deployment.
