// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.this.id}/*"]

    condition {
      test     = "StringEquals"
      values   = [random_pet.secret_user_agent.id]
      variable = "aws:UserAgent"
    }

    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}
