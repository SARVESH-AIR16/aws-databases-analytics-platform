# Module 05 — cache implementation stage

## Implemented in local code

- Optional Valkey replication group in two application private subnets.
- TLS, encryption at rest and sensitive AUTH-token input for Valkey.
- Optional TLS-enabled DAX cluster and DAX role scoped to the sample orders table
  and its indexes.
- DAX depends on the optional DynamoDB table. Port 8111 plaintext DAX rules are
  removed; the TLS client port 9111 remains.
- Offline sample validation and a small in-memory cache illustration.

## Not yet demonstrated

- No cache resource has been deployed.
- The offline hit/miss simulation is not a benchmark of ElastiCache or DAX.
- Live application integration, latency testing, load testing and cost evidence
  remain pending a regional pricing review and explicit deployment approval.

## Cleanup

Keep Terraform state until `terraform plan -destroy` and `terraform destroy` have
been reviewed and completed under the same directory, workspace, state and AWS
profile used for deployment. Then independently check for remaining cache
replication groups, DAX clusters, snapshots, logs and other project resources.
