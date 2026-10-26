# Optional provisioned Redshift demo. It is billed while running; keep disabled by default.
data "aws_iam_policy_document" "redshift_assume_role" {
  count = var.enable_redshift_stack ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "redshift_spectrum_access" {
  count = var.enable_redshift_stack ? 1 : 0

  statement {
    sid       = "ReadParquetLakeObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.analytics_lake[0].arn}/data/parquet/*"]
  }

  statement {
    sid       = "ListLakeParquetPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["data/parquet", "data/parquet/*"]
    }
  }

  statement {
    sid       = "GetLakeBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
  }

  statement {
    sid    = "ReadGlueCatalogMetadata"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = [
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:catalog",
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:database/${aws_glue_catalog_database.analytics[0].name}",
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:table/${aws_glue_catalog_database.analytics[0].name}/*"
    ]
  }
}

resource "aws_iam_role" "redshift_spectrum" {
  count = var.enable_redshift_stack ? 1 : 0

  name               = "db-analytics-redshift-spectrum-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume_role[0].json
  description        = "Read-only S3 Parquet and Glue Catalog access for Redshift Spectrum"

  tags = {
    Name   = "db-analytics-redshift-spectrum-role"
    Module = "analytics"
  }
}

resource "aws_iam_role_policy" "redshift_spectrum" {
  count = var.enable_redshift_stack ? 1 : 0

  name   = "db-analytics-redshift-spectrum-read"
  role   = aws_iam_role.redshift_spectrum[0].id
  policy = data.aws_iam_policy_document.redshift_spectrum_access[0].json
}

resource "aws_redshift_subnet_group" "analytics" {
  count = var.enable_redshift_stack ? 1 : 0

  name        = "db-analytics-redshift-subnets"
  description = "Private analytics subnets for the optional Redshift demo"
  subnet_ids  = [aws_subnet.analytics_private.id, aws_subnet.analytics_private_b.id]

  tags = {
    Name   = "db-analytics-redshift-subnets"
    Module = "analytics"
  }
}

resource "aws_security_group" "redshift_analytics" {
  count = var.enable_redshift_stack ? 1 : 0

  name                   = "db-analytics-redshift-sg"
  description            = "Private Redshift endpoint; client ingress only from application and analytics-worker security groups."
  vpc_id                 = aws_vpc.analytics.id
  revoke_rules_on_delete = true
  ingress                = []
  egress                 = []

  tags = {
    Name   = "db-analytics-redshift-sg"
    Module = "analytics"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redshift_from_application" {
  count = var.enable_redshift_stack ? 1 : 0

  security_group_id            = aws_security_group.redshift_analytics[0].id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = 5439
  to_port                      = 5439
  ip_protocol                  = "tcp"
  description                  = "Redshift SQL connections from the application security group over VPC peering"

  depends_on = [aws_vpc_peering_connection.application_analytics]
}

resource "aws_vpc_security_group_ingress_rule" "redshift_from_analytics_worker" {
  count = var.enable_redshift_stack ? 1 : 0

  security_group_id            = aws_security_group.redshift_analytics[0].id
  referenced_security_group_id = aws_security_group.analytics_worker.id
  from_port                    = 5439
  to_port                      = 5439
  ip_protocol                  = "tcp"
  description                  = "Redshift SQL connections from an analytics worker"
}

resource "aws_vpc_security_group_egress_rule" "redshift_to_s3_https" {
  count = var.enable_redshift_stack ? 1 : 0

  security_group_id = aws_security_group.redshift_analytics[0].id
  prefix_list_id    = aws_vpc_endpoint.s3_analytics.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "S3 data-lake access through the analytics VPC gateway endpoint"
}

resource "aws_redshift_cluster" "analytics" {
  count = var.enable_redshift_stack ? 1 : 0

  cluster_identifier                  = "db-analytics-redshift"
  database_name                       = "analytics"
  master_username                     = "awsuser"
  manage_master_password              = true
  node_type                           = var.redshift_node_type
  maintenance_track_name              = "current"
  cluster_type                        = "single-node"
  number_of_nodes                     = 1
  cluster_subnet_group_name           = aws_redshift_subnet_group.analytics[0].name
  vpc_security_group_ids              = [aws_security_group.redshift_analytics[0].id]
  iam_roles                           = [aws_iam_role.redshift_spectrum[0].arn]
  default_iam_role_arn                = aws_iam_role.redshift_spectrum[0].arn
  publicly_accessible                 = false
  encrypted                           = true
  enhanced_vpc_routing                = true
  automated_snapshot_retention_period = 0
  skip_final_snapshot                 = true

  depends_on = [aws_iam_role_policy.redshift_spectrum]

  tags = {
    Name   = "db-analytics-redshift"
    Module = "analytics"
  }
}
