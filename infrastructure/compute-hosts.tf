# Module 0 compute layer — optional host instances for the architecture.
# These instances are disabled by default. A bastion public IPv4 address is billable.

data "aws_ssm_parameter" "amazon_linux_2023_x86_64" {
  count = var.enable_compute_hosts ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "terraform_data" "compute_hosts_prerequisite_guard" {
  count = var.enable_compute_hosts ? 1 : 0
  lifecycle {
    precondition {
      condition     = trimspace(var.admin_cidr) != "" && can(cidrhost(trimspace(var.admin_cidr), 0)) && endswith(trimspace(var.admin_cidr), "/32") && trimspace(var.compute_ssh_public_key) != ""
      error_message = "Before enabling compute hosts, set admin_cidr to your trusted public IPv4 /32 and compute_ssh_public_key to a public SSH key. Never use 0.0.0.0/0."
    }
  }
}

resource "terraform_data" "analytics_worker_prerequisite_guard" {
  count = var.enable_analytics_worker ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.enable_compute_hosts && var.enable_analytics_stack
      error_message = "The analytics worker requires enable_compute_hosts=true and enable_analytics_stack=true."
    }
  }
}

resource "aws_key_pair" "portfolio_demo" {
  count      = var.enable_compute_hosts ? 1 : 0
  key_name   = "db-analytics-portfolio-demo"
  public_key = var.compute_ssh_public_key
  tags = {
    Name   = "db-analytics-portfolio-demo"
    Module = "compute-hosts"
  }
  depends_on = [terraform_data.compute_hosts_prerequisite_guard]
}

resource "aws_instance" "bastion" {
  count                       = var.enable_compute_hosts ? 1 : 0
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_x86_64[0].value
  instance_type               = var.compute_instance_type
  subnet_id                   = aws_subnet.application_public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.portfolio_demo[0].key_name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/bin/bash
    set -euo pipefail
    printf '%s\n' 'AWS Databases + Analytics Platform — restricted bastion host' > /etc/motd
  EOT
  root_block_device {
    volume_size           = var.compute_root_volume_gib
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name   = "db-analytics-bastion"
    Module = "compute-hosts"
    Role   = "administration"
  }
}

resource "aws_instance" "application" {
  count                       = var.enable_compute_hosts ? 1 : 0
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_x86_64[0].value
  instance_type               = var.compute_instance_type
  subnet_id                   = aws_subnet.application_private.id
  vpc_security_group_ids      = [aws_security_group.application.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.portfolio_demo[0].key_name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/bin/bash
    set -euo pipefail
    mkdir -p /opt/db-analytics-demo
    cat > /opt/db-analytics-demo/index.html <<'HTML'
    <!doctype html><html><head><title>AWS Database Analytics Demo</title></head><body>
    <h1>AWS Databases + Analytics Platform</h1>
    <p>Private application host is running. This endpoint is intentionally bound to loopback and must be viewed through an authenticated SSH tunnel.</p>
    <p>Review the repository README and architecture documentation for the eight data-platform modules.</p>
    </body></html>
    HTML
    cat > /opt/db-analytics-demo/health.json <<'JSON'
    {"status":"ok","service":"db-analytics-application","mode":"portfolio-demo"}
    JSON
    cat > /etc/systemd/system/db-analytics-demo.service <<'UNIT'
    [Unit]
    Description=Private portfolio demo page
    After=network.target
    [Service]
    Type=simple
    User=nobody
    WorkingDirectory=/opt/db-analytics-demo
    ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1 --directory /opt/db-analytics-demo
    Restart=on-failure
    [Install]
    WantedBy=multi-user.target
    UNIT
    chown -R nobody:nobody /opt/db-analytics-demo
    systemctl daemon-reload
    systemctl enable --now db-analytics-demo.service
  EOT
  root_block_device {
    volume_size           = var.compute_root_volume_gib
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name   = "db-analytics-application"
    Module = "compute-hosts"
    Role   = "application"
  }
}

resource "aws_iam_role" "analytics_worker" {
  count = var.enable_analytics_worker ? 1 : 0
  name  = "db-analytics-worker-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name   = "db-analytics-worker-ec2-role"
    Module = "compute-hosts"
  }
  depends_on = [terraform_data.analytics_worker_prerequisite_guard]
}

data "aws_iam_policy_document" "analytics_worker_s3" {
  count = var.enable_analytics_worker ? 1 : 0
  statement {
    sid       = "ListDataLakeDataPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["data", "data/*"]
    }
  }
  statement {
    sid       = "ReadWriteDataLakeObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.analytics_lake[0].arn}/data/*"]
  }
}

resource "aws_iam_role_policy" "analytics_worker_s3" {
  count  = var.enable_analytics_worker ? 1 : 0
  name   = "analytics-worker-data-prefix-access"
  role   = aws_iam_role.analytics_worker[0].id
  policy = data.aws_iam_policy_document.analytics_worker_s3[0].json
}

resource "aws_iam_instance_profile" "analytics_worker" {
  count = var.enable_analytics_worker ? 1 : 0
  name  = "db-analytics-worker-profile"
  role  = aws_iam_role.analytics_worker[0].name
}

resource "aws_instance" "analytics_worker" {
  count                       = var.enable_analytics_worker ? 1 : 0
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_x86_64[0].value
  instance_type               = var.compute_instance_type
  subnet_id                   = aws_subnet.analytics_private.id
  vpc_security_group_ids      = [aws_security_group.analytics_worker.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.portfolio_demo[0].key_name
  iam_instance_profile        = aws_iam_instance_profile.analytics_worker[0].name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/bin/bash
    set -euo pipefail
    printf '%s\n' 'Analytics worker host — S3 access is restricted to data/* in the analytics lake.' > /etc/motd
  EOT
  root_block_device {
    volume_size           = var.compute_root_volume_gib
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name   = "db-analytics-worker"
    Module = "compute-hosts"
    Role   = "analytics-worker"
  }
  depends_on = [aws_iam_role_policy.analytics_worker_s3]
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh_to_analytics_worker" {
  count                        = var.enable_analytics_worker ? 1 : 0
  security_group_id            = aws_security_group.bastion.id
  referenced_security_group_id = aws_security_group.analytics_worker.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Restricted bastion administration to the private analytics worker over VPC peering"
}

resource "aws_vpc_security_group_ingress_rule" "analytics_worker_ssh_from_bastion" {
  count                        = var.enable_analytics_worker ? 1 : 0
  security_group_id            = aws_security_group.analytics_worker.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH to the analytics worker from the bastion security group only"
}

output "bastion_public_ip" {
  description = "Public IP for the restricted bastion host; null while compute hosts are disabled."
  value       = try(aws_instance.bastion[0].public_ip, null)
}

output "application_private_ip" {
  description = "Private application host IP; null while compute hosts are disabled."
  value       = try(aws_instance.application[0].private_ip, null)
}

output "analytics_worker_private_ip" {
  description = "Private analytics worker IP; null while the optional worker is disabled."
  value       = try(aws_instance.analytics_worker[0].private_ip, null)
}
