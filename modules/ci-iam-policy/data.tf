// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

data "aws_partition" "this" {
  count = var.create ? 1 : 0
}

locals {
  infrastructure_bucket_names = distinct(compact([
    var.bucket_name,
    var.log_bucket_name != "" ? var.log_bucket_name : "${var.bucket_name}-logs",
  ]))
}

data "aws_iam_policy_document" "content" {
  count = var.create && var.attach_content_permissions ? 1 : 0

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"
    resources = [
      format(
        "arn:%s:s3:::%s",
        data.aws_partition.this[0].partition,
        var.bucket_name,
      ),
    ]

    sid = "StaticWebsiteContentPermissionsS3Bucket"

    dynamic "condition" {
      for_each = var.required_resource_tags

      content {
        test     = "StringEquals"
        values   = [condition.value]
        variable = "aws:ResourceTag/${condition.key}"
      }
    }
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]

    effect = "Allow"
    resources = [
      format(
        "arn:%s:s3:::%s/*",
        data.aws_partition.this[0].partition,
        var.bucket_name,
      ),
    ]

    sid = "StaticWebsiteContentPermissionsS3Object"
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    effect    = "Allow"
    resources = [var.cloudfront_distribution_arn]
    sid       = "StaticWebsiteContentPermissionsCloudFront"

    dynamic "condition" {
      for_each = var.required_resource_tags

      content {
        test     = "StringEquals"
        values   = [condition.value]
        variable = "aws:ResourceTag/${condition.key}"
      }
    }
  }
}

data "aws_iam_policy_document" "infrastructure" {
  count = var.create && var.attach_infrastructure_permissions ? 1 : 0

  statement {
    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate",
    ]

    effect    = "Allow"
    resources = ["*"]
    sid       = "StaticWebsiteInfrastructurePermissionsAcm"
  }

  statement {
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListTagsForResource",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:UpdateDistribution",
    ]

    effect    = "Allow"
    resources = ["*"]
    sid       = "StaticWebsiteInfrastructurePermissionsCloudFront"
  }

  statement {
    actions = [
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:GetOriginAccessControlConfig",
      "cloudfront:ListOriginAccessControls",
      "cloudfront:UpdateOriginAccessControl",
    ]

    effect    = "Allow"
    resources = ["*"]
    sid       = "StaticWebsiteInfrastructurePermissionsCloudFrontOac"
  }

  statement {
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:DeleteBucketOwnershipControls",
      "s3:DeleteBucketPolicy",
      "s3:DeleteBucketPublicAccessBlock",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:PutBucketLogging",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
    ]

    effect = "Allow"
    resources = [for bucket_name in local.infrastructure_bucket_names : format(
      "arn:%s:s3:::%s",
      data.aws_partition.this[0].partition,
      bucket_name,
    )]

    sid = "StaticWebsiteInfrastructurePermissionsS3"
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    effect = "Allow"
    resources = [for bucket_name in local.infrastructure_bucket_names : format(
      "arn:%s:s3:::%s/*",
      data.aws_partition.this[0].partition,
      bucket_name,
    )]

    sid = "StaticWebsiteInfrastructurePermissionsS3Object"
  }

  statement {
    actions   = ["s3:ListAllMyBuckets"]
    effect    = "Allow"
    resources = ["*"]
    sid       = "StaticWebsiteInfrastructurePermissionsS3Global"
  }
}

data "aws_iam_policy_document" "combined" {
  count = var.create ? 1 : 0

  source_policy_documents = compact([
    var.attach_content_permissions ? data.aws_iam_policy_document.content[0].json : "",
    var.attach_infrastructure_permissions ? data.aws_iam_policy_document.infrastructure[0].json : "",
  ])
}
