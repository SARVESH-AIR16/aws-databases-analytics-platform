# Terraform network foundation

The Terraform foundation defines two VPCs (`10.0.0.0/16` for application and
`10.1.0.0/16` for analytics), five subnets across `ap-south-1a` and
`ap-south-1b`, an Internet Gateway for the application VPC, route tables,
VPC peering, and bidirectional private routes.

The network hardening layer adds tier-specific security groups and scoped
security-group rules for a future bastion, application, RDS Proxy, database,
cache, DAX, and analytics worker. No compute, database, cache, DAX, or analytics
service is deployed by creating security groups alone.

The bastion's SSH ingress is disabled by default. To add it later, pass an
explicit trusted IPv4 CIDR using `-var='admin_cidr=x.x.x.x/32'`. Never use
`0.0.0.0/0`. The default database port is PostgreSQL `5432`; MySQL `3306` can
be selected with `-var='database_port=3306'`. Match this setting to the actual
engine before deploying database modules.

S3 gateway endpoints are associated with the application and analytics private
route tables; a DynamoDB gateway endpoint is associated with the application
private route table. These endpoints provide a route to the services; IAM and
bucket/table policies still determine whether requests are permitted. The
private subnets have no `0.0.0.0/0` route or NAT Gateway by default.

## Safety gates

1. Confirm CIDRs do not overlap VPN, home, or corporate networks.
2. Verify the AWS identity and least-privilege deployment permissions.
3. Run Terraform formatting and validation.
4. Generate and inspect a fresh plan before any apply.
5. Check current regional pricing for the services to be deployed.
6. Do not commit credentials, `.tfstate`, `.tfplan`, or secret-bearing tfvars.
7. Require explicit approval before deployment; no AWS resources have been
   deployed just by validating or planning this configuration.
