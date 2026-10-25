# Module 7 — optional Kinesis Data Stream and a scoped producer-policy template.
resource "aws_kinesis_stream" "orders" {
  count = var.enable_kinesis_stream ? 1 : 0

  name             = "db-analytics-orders-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name   = "db-analytics-orders-stream"
    Module = "streaming"
  }
}

# This output is a policy template only. It does not create or attach a producer role.
data "aws_iam_policy_document" "kinesis_producer_access" {
  count = var.enable_kinesis_stream ? 1 : 0

  statement {
    sid    = "WriteOrderEventsToSingleStream"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStreamSummary",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = [aws_kinesis_stream.orders[0].arn]
  }

  # Producers writing to an SSE-KMS stream need data-key generation permission.
  statement {
    sid       = "GenerateKinesisDataKeyForThisStream"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
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
}
