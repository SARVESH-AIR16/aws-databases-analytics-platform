# One delivery role is used for both the Kinesis source and S3 destination.
# Firehose trust is restricted to this account and this exact delivery stream.
data "aws_iam_policy_document" "firehose_assume_role" {
  count = var.enable_firehose_delivery ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.analytics[0].account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.analytics[0].partition}:firehose:${var.aws_region}:${data.aws_caller_identity.analytics[0].account_id}:deliverystream/db-analytics-orders-firehose"
      ]
    }
  }
}

data "aws_iam_policy_document" "firehose_delivery_access" {
  count = var.enable_firehose_delivery ? 1 : 0

  statement {
    sid    = "ReadConfiguredKinesisSource"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards"
    ]
    resources = [aws_kinesis_stream.orders[0].arn]
  }

  # SSE-KMS decryption is allowed only through Kinesis for this stream's encryption context.
  # The AWS-managed alias avoids creating a separately billed customer-managed key.
  statement {
    sid       = "DecryptConfiguredKinesisSource"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["kinesis.${var.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:kinesis:arn"
      values   = [aws_kinesis_stream.orders[0].arn]
    }
  }

  statement {
    sid       = "GetAnalyticsBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.analytics_lake[0].arn]
  }

  statement {
    sid    = "ListOnlyStreamingDeliveryPrefixes"
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
        "data/streaming/",
        "data/streaming/*",
        "data/streaming-errors/",
        "data/streaming-errors/*"
      ]
    }
  }

  statement {
    sid    = "WriteOnlyStreamingObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.analytics_lake[0].arn}/data/streaming/*",
      "${aws_s3_bucket.analytics_lake[0].arn}/data/streaming-errors/*"
    ]
  }
}

resource "aws_iam_role" "firehose_delivery" {
  count = var.enable_firehose_delivery ? 1 : 0

  name               = "db-analytics-firehose-role"
  description        = "Reads the configured order stream and writes only the streaming prefixes in the analytics bucket."
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role[0].json

  tags = {
    Name   = "db-analytics-firehose-role"
    Module = "streaming"
  }
}

resource "aws_iam_role_policy" "firehose_delivery" {
  count = var.enable_firehose_delivery ? 1 : 0

  name   = "db-analytics-firehose-delivery-access"
  role   = aws_iam_role.firehose_delivery[0].id
  policy = data.aws_iam_policy_document.firehose_delivery_access[0].json
}
