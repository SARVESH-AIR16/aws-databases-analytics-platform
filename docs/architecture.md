# Architecture overview

## Application VPC — `10.0.0.0/16`

- Public subnet `10.0.1.0/24` in `ap-south-1a`, reserved for a controlled
  administration entry point. It has an Internet Gateway route but does not
  automatically assign public IPv4 addresses.
- Private subnets `10.0.2.0/24` in `ap-south-1a` and `10.0.3.0/24` in
  `ap-south-1b` for the application and database tier.
- Security groups reserved for the future bastion, application, RDS Proxy,
  relational database, ElastiCache-compatible cache, and DynamoDB DAX tiers.
- S3 and DynamoDB gateway endpoints on the application private route table.

## Analytics VPC — `10.1.0.0/16`

- Private subnets `10.1.1.0/24` in `ap-south-1a` and `10.1.2.0/24` in
  `ap-south-1b` for private analytics processing.
- A worker security group with no inbound rules by default and S3 HTTPS egress.
- S3 gateway endpoint on the analytics private route table.

## Connectivity and services

- VPC peering plus explicit routes connects the private VPC address spaces;
  it is not transitive and does not imply that security groups permit traffic.
- Planned managed services include RDS/Aurora, RDS Proxy, ElastiCache, DynamoDB,
  DAX, S3 Parquet, Glue Catalog, Athena, Redshift, Kinesis, Firehose and AWS DMS.
- The managed-service modules and any additional endpoint/access rules still need
  implementation and testing. This foundation does not create those services.

## Data-flow examples to implement and test

1. Application workload -> RDS Proxy -> relational database over a private path.
2. Application workload -> cache/DAX with tier-scoped security-group rules.
3. Application/analytics worker -> S3 via gateway endpoint and IAM-controlled access.
4. Application -> DynamoDB via the application's gateway endpoint.
5. Kinesis Data Streams -> Firehose -> S3 when the streaming module is enabled.
6. Glue Catalog describes S3 datasets; Athena queries the S3 data; Redshift is
   an optional warehouse path subject to cost review.
7. AWS DMS migrates from a supported source to a supported target after the
   migration module, network path, secrets and cleanup plan are reviewed.
