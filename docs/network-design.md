# Network design — proposal for review

The original drawing's `28.0.0.0/16` and `28.200.0.0/16` values are illustrative only. They are not RFC1918 private ranges and must not be copied into the deployment.

## Proposed private address plan

| Component | Proposed CIDR | Purpose |
|---|---|---|
| VPC 1 — application | `10.0.0.0/16` | Application and relational database tier |
| VPC 1 — public subnet | `10.0.1.0/24` | Controlled admin/bastion entry point |
| VPC 1 — private subnet | `10.0.2.0/24` | Application EC2 and private database tier |
| VPC 2 — analytics | `10.1.0.0/16` | Analytics and data processing |
| VPC 2 — private subnet | `10.1.1.0/24` | Optional analytics worker |

These are proposed defaults, not deployed resources. Confirm they do not overlap with existing networks/VPNs before use.

## Route intent
- VPC 1 public subnet: local route plus Internet Gateway default route only if required.
- VPC 1 private subnet: local route and VPC 2 CIDR route via peering for explicitly required private communication.
- VPC 2 private subnet: local route and VPC 1 CIDR route via peering for explicitly required private communication.
- Do not add `0.0.0.0/0` routes to private subnets until the egress design and cost are reviewed.

## Security intent
- No database public access.
- SSH only from a known admin IP or via a safer managed access pattern; never `0.0.0.0/0`.
- App-to-database access only on the selected database port.
- Use least-privilege IAM roles and service-specific endpoints where appropriate.
- Enable logs only after checking their cost and retention.
