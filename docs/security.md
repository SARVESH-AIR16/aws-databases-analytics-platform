# Security baseline

- Keep credentials, Terraform state, saved plans, and secret-bearing variable
  files out of the repository.
- Use an appropriately permissioned non-root identity; prefer temporary
  credentials when practical and avoid long-lived access keys where possible.
- Do not expose databases to the public internet.
- Do not allow SSH/RDP from `0.0.0.0/0`.
- The bastion SSH ingress rule is not created unless `admin_cidr` is set to an
  explicit trusted CIDR. Prefer managed access patterns where feasible.
- App-to-proxy, proxy-to-database, app-to-cache, and app-to-DAX rules are
  separated and scoped to security-group references and specific ports.
- The database port defaults to PostgreSQL 5432; use 3306 only when the chosen
  engine and downstream service configuration are set to MySQL.
- Application egress to S3/DynamoDB uses gateway-endpoint prefix lists on HTTPS.
- An endpoint is a network path, not permission. IAM, bucket/table policies,
  encryption settings, and service policies remain necessary.
- The analytics worker has no inbound rules by default and S3 HTTPS egress only.
- Keep cross-VPC rules closed until a specific application flow is documented.
- Check CloudTrail and logging retention/costs before enabling additional logs.
