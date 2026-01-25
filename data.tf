// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

data "aws_partition" "this" {
  count = var.create ? 1 : 0
}

data "aws_iam_policy_document" "this" {
  count = var.create && (var.create_cloudfront_distribution || var.cloudfront_distribution_arn != "") ? 1 : 0

  statement {
    actions = ["s3:GetObject"]
    effect  = "Allow"
    resources = [
      format(
        "arn:%s:s3:::%s/*",
        data.aws_partition.this[0].partition,
        aws_s3_bucket.this[0].id,
      ),
    ]

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
