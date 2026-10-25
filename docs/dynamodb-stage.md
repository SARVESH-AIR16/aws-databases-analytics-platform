# Module 04 implementation and cost gate

## Implemented locally

- Optional Terraform DynamoDB orders table, disabled by default.
- Pay-per-request billing mode and best-effort maximum read/write request units
  on the table and GSI.
- Composite key: `customer_id` + `order_id`.
- GSI `status-created-index` for status/time queries.
- Optional PITR, TTL and Streams, each disabled by default.
- EC2-trusted IAM role, instance profile and table/index-scoped item access.
- Three synthetic sample orders and an offline schema validator.
- Explicit AWS demo actions: seed, get, query status, and cleanup known sample keys.

## Not yet done

- No DynamoDB table, IAM role or instance profile has been deployed by this module.
- No live DynamoDB operations have been executed.
- The role is not yet attached to application compute because that module is not implemented.
- The optional Streams setting is a future integration point; it does not itself implement Kinesis or Firehose ingestion.

## Cost gate

Before enabling `enable_dynamodb_stack`, review the current AWS pricing page for
`ap-south-1`. DynamoDB charges depend on table storage and requests. PITR,
Streams, backups and additional index storage or traffic may add charges.
The maximum throughput settings help bound expected use, but are best-effort
and not a hard spending limit. AWS Budgets are alerts, not hard caps.

Source: [Amazon DynamoDB pricing](https://aws.amazon.com/dynamodb/pricing/)
