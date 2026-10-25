# Optional Glue crawler role. The crawler is created only when explicitly enabled.
data "aws_iam_policy_document" "glue_crawler_assume_role" {
  count = var.enable_glue_crawler ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_crawler_access" {
  count = var.enable_glue_crawler ? 1 : 0

  statement {
    sid       = "ReadParquetObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.analytics_lake[0].arn}/data/parquet/*"]
  }

  statement {
    sid       = "ListParquetPrefix"
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
    sid       = "GetBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
  }

  # Glue discovery actions are read/metadata-write only; the S3 data path is scoped above.
  statement {
    sid    = "CatalogDiscoveryAndTableMetadata"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:CreatePartition",
      "glue:BatchCreatePartition"
    ]
    resources = [
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:catalog",
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:database/${aws_glue_catalog_database.analytics[0].name}",
      "arn:${data.aws_partition.analytics[0].partition}:glue:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:table/${aws_glue_catalog_database.analytics[0].name}/*"
    ]
  }

  statement {
    sid    = "CrawlerLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0

  name               = "db-analytics-glue-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_crawler_assume_role[0].json
  description        = "On-demand Glue crawler role scoped to the analytics Parquet prefix"

  tags = {
    Name   = "db-analytics-glue-crawler-role"
    Module = "analytics"
  }
}

resource "aws_iam_role_policy" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0

  name   = "db-analytics-glue-crawler-access"
  role   = aws_iam_role.glue_crawler[0].id
  policy = data.aws_iam_policy_document.glue_crawler_access[0].json
}

resource "aws_glue_crawler" "parquet" {
  count = var.enable_glue_crawler ? 1 : 0

  name          = "db-analytics-parquet-crawler"
  role          = aws_iam_role.glue_crawler[0].arn
  database_name = aws_glue_catalog_database.analytics[0].name
  description   = "On-demand schema discovery for Parquet order records"

  s3_target {
    path = "s3://${aws_s3_bucket.analytics_lake[0].bucket}/data/parquet/"
  }

  schema_change_policy {
    delete_behavior = "DEPRECATE_IN_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  tags = {
    Name   = "db-analytics-parquet-crawler"
    Module = "analytics"
  }

  depends_on = [aws_iam_role_policy.glue_crawler]
}
