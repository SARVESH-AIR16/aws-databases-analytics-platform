# Module 04 — Amazon DynamoDB

## Status

Terraform configuration and offline sample validation are drafted. The stack
is disabled by default and is not deployed or tested against a live table.

## Data model

`db-analytics-orders` is an optional single-region DynamoDB table using
`PAY_PER_REQUEST` billing. Its primary key is `customer_id` (partition key)
and `order_id` (sort key). The `status-created-index` GSI supports queries by
order status and creation timestamp while projecting only `order_total` and
`currency` in addition to key attributes.

The configuration sets a best-effort maximum of 100 on-demand read request
units and 100 write request units per second for the table and GSI. Exceeding
these settings can throttle requests; this is not a hard billing cap.

DynamoDB encrypts table data at rest by default with an AWS-owned key; this
module does not create a customer-managed KMS key. Point-in-time recovery,
TTL and DynamoDB Streams are optional and disabled by default. Enabling PITR
can add backup charges; enable streams only when implementing the streaming
integration.

## Least-privilege role

When the stack is enabled, Terraform creates an EC2-trusted role and instance
profile for future application compute. Its inline policy grants item operations
and Query only on this table and its indexes; it does not grant `Scan`, table
creation or deletion, or broad access to other tables. No EC2 instance is
created by this module.

## Local tests

From the repository root:

```bash
python3 tests/validate-dynamodb-config.py
python3 scripts/dynamodb_demo.py validate-sample
```

Both tests run without AWS access or boto3. For live operations, install boto3
and first deploy the optional table through an explicitly approved Terraform
plan. Only then use the explicit `seed`, `get` or `query-status` actions.

```bash
python3 -m pip install boto3
python3 scripts/dynamodb_demo.py seed --profile ghost-hunter-cli
python3 scripts/dynamodb_demo.py get --profile ghost-hunter-cli
python3 scripts/dynamodb_demo.py query-status --status PAID --profile ghost-hunter-cli
python3 scripts/dynamodb_demo.py cleanup-demo --confirm-demo-cleanup --profile ghost-hunter-cli
```

The cleanup command removes only the three known sample keys in
`data/sample/orders.json`; it does not delete the table. Never run the AWS
actions before the optional table has been reviewed and deliberately deployed.

## Cost and cleanup gate

The stack flag is `enable_dynamodb_stack`, which defaults to `false`. Table
storage and read/write requests are billable. Optional PITR, Streams, indexes,
and backup storage can add costs. On-demand throughput maximums are a
best-effort traffic guardrail, not a budget cap. Check current Mumbai-region
pricing, enable only the needed features, and define cleanup before deployment.
