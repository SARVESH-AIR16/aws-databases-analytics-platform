# Module 6 — Analytics foundations. Everything in this file is opt-in.
data "aws_caller_identity" "analytics" {
  count = var.enable_analytics_stack ? 1 : 0
}

data "aws_partition" "analytics" {
  count = var.enable_analytics_stack ? 1 : 0
}

resource "aws_s3_bucket" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket        = "db-analytics-lake-${data.aws_caller_identity.analytics[0].account_id}-${var.aws_region}"
  force_destroy = true

  tags = {
    Name   = "db-analytics-lake"
    Module = "analytics"
  }
}

resource "aws_s3_bucket_public_access_block" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket                  = aws_s3_bucket.analytics_lake[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket = aws_s3_bucket.analytics_lake[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket = aws_s3_bucket.analytics_lake[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket = aws_s3_bucket.analytics_lake[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket = aws_s3_bucket.analytics_lake[0].id

  rule {
    id     = "expire-athena-results"
    status = "Enabled"
    filter {
      prefix = "athena-results/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "expire-streaming-data"
    status = "Enabled"
    filter {
      prefix = "data/streaming/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "expire-streaming-error-data"
    status = "Enabled"
    filter {
      prefix = "data/streaming-errors/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "expire-dms-migration-data"
    status = "Enabled"
    filter {
      prefix = "data/dms-migration/"
    }
    expiration {
      days = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "analytics_bucket_https_only" {
  count = var.enable_analytics_stack ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.analytics_lake[0].arn,
      "${aws_s3_bucket.analytics_lake[0].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "analytics_lake" {
  count = var.enable_analytics_stack ? 1 : 0

  bucket = aws_s3_bucket.analytics_lake[0].id
  policy = data.aws_iam_policy_document.analytics_bucket_https_only[0].json
}

resource "aws_glue_catalog_database" "analytics" {
  count = var.enable_analytics_stack ? 1 : 0

  name         = "dba_analytics_lake"
  description  = "Portfolio data-lake catalog for synthetic order analytics"
  location_uri = "s3://${aws_s3_bucket.analytics_lake[0].bucket}/data/"

  depends_on = [aws_s3_bucket_policy.analytics_lake]
}

resource "aws_athena_workgroup" "analytics" {
  count = var.enable_analytics_stack ? 1 : 0

  name        = "db-analytics-wg"
  description = "Cost-controlled workgroup for the portfolio data lake"
  state       = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff_bytes

    result_configuration {
      output_location = "s3://${aws_s3_bucket.analytics_lake[0].bucket}/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
    engine_version {
      selected_engine_version = "AUTO"
    }
  }
}
