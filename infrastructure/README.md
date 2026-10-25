# Terraform network foundation

Defines two VPCs, three subnets, an internet gateway,
route tables, subnet associations, and VPC peering.

No EC2 instances, databases, NAT Gateways, or VPC endpoints
are included in this initial network configuration.

The public route table has an internet-gateway route, but
subnets do not automatically assign public IPv4 addresses.
Private subnets have no default internet route.

Review existing network CIDRs, AWS permissions, regional
pricing, and the Terraform plan before deployment.
Never commit credentials or Terraform state files.
