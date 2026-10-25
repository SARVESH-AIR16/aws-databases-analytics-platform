# Security baseline

- Keep credentials outside the repository.
- Use IAM roles and least privilege.
- Avoid long-lived IAM user access keys where possible.
- Do not expose databases to the public internet.
- Restrict inbound rules to known sources and required ports.
- Store application secrets in an appropriate secrets service only after reviewing cost and access requirements.
- Do not commit AWS account IDs, tokens, keys, state files, or personal IP addresses.
- Review CloudTrail/logging retention and charges before enabling additional logging.
