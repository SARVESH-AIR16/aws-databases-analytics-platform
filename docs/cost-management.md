# Cost-management checklist

Before creating or applying any resource:

- Verify the AWS account, non-root CLI profile, region, and required permissions.
- Review the billing dashboard, current budgets, and alerts. An alert is not a
  hard spending cap.
- Check current pricing for `ap-south-1` for each service before deploying it.
- Identify resources with hourly, storage, request, public IPv4, or data-transfer
  charges, and define cleanup steps before each test.
- VPCs, route tables, security groups, and VPC peering have no resource-hour fee;
  data transfer across peering can still cost money.
- AWS states that S3 and DynamoDB gateway endpoints have no additional endpoint
  charge. Normal S3/DynamoDB request/storage charges and other usage still apply.
- Avoid NAT Gateways by default; they have ongoing hourly and data-processing
  charges. Prefer a gateway endpoint for S3/DynamoDB where appropriate.
- RDS/Aurora, RDS Proxy, ElastiCache, DAX, Redshift, DMS, Kinesis/Firehose,
  interface endpoints, EC2, public IPv4 addresses and data processing can incur
  charges; validate actual regional rates before choosing configurations.
- Use synthetic data and short-lived tests. Do not start optional managed services
  until their purpose, estimate, teardown path, and approval are documented.
- Verify resource deletion after each deployment stage and review billing after tests.
