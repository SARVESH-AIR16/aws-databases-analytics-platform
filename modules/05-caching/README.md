# Module 05 — Caching with ElastiCache and DynamoDB Accelerator (DAX)

## Goal

Demonstrate where an application cache and a DynamoDB-specific accelerator fit
in an AWS data platform, while keeping the infrastructure optional and cost-aware.

## Components

- **Amazon ElastiCache for Valkey** — private application key/value caching.
- **Amazon DynamoDB Accelerator (DAX)** — an in-memory cache for supported
  DynamoDB access patterns, used here with the orders table.
- **Private subnet groups and security groups** — keep cache endpoints off the
  public internet and restrict traffic to the intended application tier.
- **Encryption and access controls** — ElastiCache at-rest encryption and TLS,
  a sensitive AUTH-token variable, DAX TLS, and narrowly scoped DAX IAM access.

## Cost and deployment defaults

Both stacks are disabled by default:

- `enable_elasticache_stack = false`
- `enable_dax_stack = false`

DAX also requires the DynamoDB stack to be enabled. The default configurations
are small demonstration settings, not highly available production settings.
ElastiCache Multi-AZ/failover needs at least two nodes and increases costs.
Do not enable either stack until reviewing current `ap-south-1` pricing and the
planned Terraform changes. Terraform plans are estimates, not billing caps.

## Local validation

Run these commands from the repository root:

```bash
terraform -chdir=infrastructure fmt -check -recursive
terraform -chdir=infrastructure validate
python3 tests/validate-cache-config.py
python3 scripts/cache_demo.py validate-sample
python3 scripts/cache_demo.py simulate
```

The demo uses an in-memory Python dictionary. Its hit ratio and elapsed time are
illustrative local simulation results, **not** AWS service performance evidence.
The sample validation makes no AWS API calls.

## Current status

Terraform configuration, static guardrail tests, sample validation, and offline
simulation are implemented locally. This module has not been deployed to AWS.
The stacks remain disabled by default. A temporary demonstration must be
approved after cost review; capture real evidence if deployed, then destroy the
resources and verify cleanup before publishing the project results.
