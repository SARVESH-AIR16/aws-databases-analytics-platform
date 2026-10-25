# Network design — hardened target

## Private address plan

| Component | CIDR | Availability Zone | Purpose |
|---|---|---|---|
| Application VPC | `10.0.0.0/16` | Regional | Application and database network |
| Application public subnet | `10.0.1.0/24` | `ap-south-1a` | Future controlled administration entry point |
| Application private subnet A | `10.0.2.0/24` | `ap-south-1a` | Application and private data tier |
| Application private subnet B | `10.0.3.0/24` | `ap-south-1b` | Multi-AZ placement option |
| Analytics VPC | `10.1.0.0/16` | Regional | Analytics network |
| Analytics private subnet A | `10.1.1.0/24` | `ap-south-1a` | Optional analytics worker |
| Analytics private subnet B | `10.1.2.0/24` | `ap-south-1b` | Multi-AZ placement option |

The CIDRs passed the project's local overlap/containment check. They still must
be compared against any VPN, home, and corporate network ranges before deployment.

## Route intent

- The public route table has a route to the application VPC's Internet Gateway.
- The public subnet does not auto-assign public IPv4 addresses.
- Application private route table: local VPC route, route to the analytics CIDR
  through VPC peering, and S3/DynamoDB gateway endpoint routes managed by AWS.
- Analytics private route table: local VPC route, route to the application CIDR
  through VPC peering, and an S3 gateway endpoint route managed by AWS.
- No private subnet has a `0.0.0.0/0` route. No NAT Gateway is defined.

## Security-group intent

- Bastion SSH ingress is absent by default; an explicit trusted administrator
  CIDR is required before that ingress rule exists.
- Application administrative SSH accepts traffic only from the bastion group.
- RDS Proxy accepts the configured database port only from the application SG.
- The database SG accepts that port only from the proxy SG.
- Cache and DAX client ports accept traffic only from the application SG.
- Application/worker egress is scoped to the declared tier dependencies and
  S3/DynamoDB gateway-endpoint prefix lists.
- There is no general cross-VPC application ingress rule. Add one only after
  a specific service flow and port have been justified.

## Managed-service connectivity caveats

Gateway endpoints support S3 and DynamoDB only. Glue, Athena, Kinesis, Firehose,
AWS APIs, Systems Manager, and other services have separate connectivity models.
Where a private workload needs interface endpoints, their hourly/data charges
must be reviewed before creating them. VPC peering is non-transitive and does
not automatically grant access to managed services.
