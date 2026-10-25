# Architecture overview

## Logical components

### VPC 1 — Application network
- Public subnet: controlled administration entry point. Do not expose SSH/RDP to the world.
- Private subnet: application EC2.
- Database tier: RDS/Aurora, RDS Proxy where justified, and ElastiCache where justified.
- Internet Gateway: attached to VPC 1; routes only from subnets whose route tables explicitly allow internet routes.

### VPC 2 — Analytics network
- Private subnet and optional analytics worker EC2.
- S3 Parquet data lake.
- DynamoDB for key-value/document access patterns.
- Kinesis Data Streams and Firehose for event ingestion and delivery.
- Glue Data Catalog and Athena for catalog/query.
- Redshift for warehouse workloads, subject to cost review.
- AWS DMS for migration/replication exercises, subject to cost review.

## Data-flow examples
1. Application EC2 → RDS/Aurora through tightly scoped security-group rules and private connectivity.
2. Application events → Kinesis Data Streams → Firehose → S3 (when streaming is enabled).
3. Glue Catalog describes S3 datasets; Athena queries the S3 data.
4. Redshift is an optional warehouse path; it is not required for the first milestone.
5. AWS DMS migrates/replicates from a supported source to a supported target when configured.

## Network caveats
- Use non-overlapping RFC1918 CIDRs and verify all subnet ranges are contained in their VPC CIDR.
- VPC peering requires routes on both sides and security rules that allow the intended traffic.
- VPC peering is non-transitive.
- S3, DynamoDB, Athena, Glue, Kinesis, Firehose, and other managed services have different network-access models. Peering alone does not make every service reachable privately.
- Do not create a NAT Gateway as a default shortcut; assess VPC endpoints, service access patterns, and cost first.
