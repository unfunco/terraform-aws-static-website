// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

data "aws_partition" "this" {
  count = var.create ? 1 : 0
}

data "aws_iam_policy_document" "this" {
  count = var.create ? 1 : 0

  dynamic "statement" {
    for_each = local.grant_cloudfront_access ? [1] : []

    content {
      actions = ["s3:GetObject"]
      effect  = "Allow"
      resources = [
        format(
          "arn:%s:s3:::%s/*",
          data.aws_partition.this[0].partition,
          local.bucket_name,
        ),
      ]
      sid = "AllowCloudFrontRead"

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [try(aws_cloudfront_distribution.this[0].arn, var.cloudfront_distribution_arn)]
      }

      principals {
        identifiers = ["cloudfront.${data.aws_partition.this[0].dns_suffix}"]
        type        = "Service"
      }
    }
  }

  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      format("arn:%s:s3:::%s", data.aws_partition.this[0].partition, local.bucket_name),
      format("arn:%s:s3:::%s/*", data.aws_partition.this[0].partition, local.bucket_name),
    ]
    sid = "DenyInsecureTransport"

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }

    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}

data "aws_caller_identity" "this" {
  count = local.allow_s3_access_logs ? 1 : 0
}

data "aws_canonical_user_id" "this" {
  count = local.create_log_bucket_acl ? 1 : 0
}

data "aws_cloudfront_log_delivery_canonical_user_id" "this" {
  count = local.create_log_bucket_acl ? 1 : 0
}

data "aws_iam_policy_document" "logs" {
  count = local.create_log_bucket ? 1 : 0

  dynamic "statement" {
    for_each = local.allow_s3_access_logs ? [1] : []

    content {
      actions = ["s3:PutObject"]
      effect  = "Allow"
      resources = [
        format(
          "arn:%s:s3:::%s/%s/s3/*",
          data.aws_partition.this[0].partition,
          local.log_bucket_name,
          local.log_bucket_target_prefix,
        ),
      ]
      sid = "AllowS3ServerAccessLogs"

      condition {
        test     = "ArnLike"
        values   = [format("arn:%s:s3:::%s", data.aws_partition.this[0].partition, local.bucket_name)]
        variable = "aws:SourceArn"
      }

      condition {
        test     = "StringEquals"
        values   = [data.aws_caller_identity.this[0].account_id]
        variable = "aws:SourceAccount"
      }

      principals {
        identifiers = ["logging.s3.${data.aws_partition.this[0].dns_suffix}"]
        type        = "Service"
      }
    }
  }

  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      format("arn:%s:s3:::%s", data.aws_partition.this[0].partition, local.log_bucket_name),
      format("arn:%s:s3:::%s/*", data.aws_partition.this[0].partition, local.log_bucket_name),
    ]
    sid = "DenyInsecureTransport"

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }

    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}
