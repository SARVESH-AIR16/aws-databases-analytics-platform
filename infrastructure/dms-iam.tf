# AWS DMS requires these account-level service role names. Before deployment,
# check whether they already exist; import existing roles into this Terraform state
# rather than trying to create duplicate role names.
data "aws_caller_identity" "dms" {
  count = local.dms_resources_enabled ? 1 : 0
}

data "aws_partition" "dms" {
  count = local.dms_resources_enabled ? 1 : 0
}

data "aws_iam_policy_document" "dms_service_trust" {
  count = local.dms_resources_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.dms[0].account_id]
    }
  }
}

resource "aws_iam_role" "dms_vpc" {
  count              = local.dms_resources_enabled ? 1 : 0
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms_service_trust[0].json
  description        = "AWS DMS VPC network management service role."
  tags = {
    Name   = "dms-vpc-role"
    Module = "migration"
  }
  depends_on = [terraform_data.dms_prerequisite_guard]
}

resource "aws_iam_role_policy_attachment" "dms_vpc" {
  count      = local.dms_resources_enabled ? 1 : 0
  role       = aws_iam_role.dms_vpc[0].name
  policy_arn = "arn:${data.aws_partition.dms[0].partition}:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role" "dms_cloudwatch_logs" {
  count              = local.dms_resources_enabled ? 1 : 0
  name               = "dms-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.dms_service_trust[0].json
  description        = "AWS DMS CloudWatch logging service role."
  tags = {
    Name   = "dms-cloudwatch-logs-role"
    Module = "migration"
  }
  depends_on = [terraform_data.dms_prerequisite_guard]
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs" {
  count      = local.dms_resources_enabled ? 1 : 0
  role       = aws_iam_role.dms_cloudwatch_logs[0].name
  policy_arn = "arn:${data.aws_partition.dms[0].partition}:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_iam_role" "dms_s3_access" {
  count              = local.dms_resources_enabled ? 1 : 0
  name               = "db-analytics-dms-s3-role"
  assume_role_policy = data.aws_iam_policy_document.dms_service_trust[0].json
  description        = "AWS DMS S3 target access limited to the migration output prefix."
  tags = {
    Name   = "db-analytics-dms-s3-role"
    Module = "migration"
  }
  depends_on = [terraform_data.dms_prerequisite_guard]
}

data "aws_iam_policy_document" "dms_s3_access" {
  count = local.dms_resources_enabled ? 1 : 0

  statement {
    sid       = "GetAnalyticsBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
  }

  statement {
    sid    = "ListOnlyDMSMigrationPrefix"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "data/dms-migration",
        "data/dms-migration/*"
      ]
    }
  }

  statement {
    sid    = "WriteAndVerifyDMSMigrationObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.analytics_lake[0].arn}/data/dms-migration/*"]
  }
}

resource "aws_iam_role_policy" "dms_s3_access" {
  count  = local.dms_resources_enabled ? 1 : 0
  name   = "dms-write-migration-prefix"
  role   = aws_iam_role.dms_s3_access[0].id
  policy = data.aws_iam_policy_document.dms_s3_access[0].json
}
