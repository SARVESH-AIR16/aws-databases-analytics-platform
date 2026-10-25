# Network hardening change note

This patch proposes a tiered security-group layer and S3/DynamoDB gateway
endpoints for the two-VPC network foundation.

- SSH to the future bastion is disabled unless an explicit trusted `admin_cidr`
  is supplied.
- Application administrative SSH is limited to the bastion security group.
- The planned database port defaults to 5432 (PostgreSQL) and can be set to 3306
  (MySQL) using `database_port`; match it to the eventual engine.
- App-to-proxy, proxy-to-database, app-to-cache, and app-to-DAX paths are explicit.
- S3 gateway endpoints exist in both private VPC route tables; the DynamoDB
  gateway endpoint is in the application private route table.
- The analytics worker has no inbound rules and HTTPS egress to the S3 endpoint.
- This is a proposed configuration update. Run format, validate, CIDR validation,
  and a fresh plan before considering deployment. Do not apply automatically.
