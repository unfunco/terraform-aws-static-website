// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

// These tests only plan, with static credentials that never reach AWS, so
// they run without an AWS account.

provider "aws" {
  access_key                  = "test"
  region                      = "eu-west-1"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

// These data sources call AWS, so their values are fixed here.

override_data {
  target = data.aws_caller_identity.this
  values = {
    account_id = "123456789012"
  }
}

override_data {
  target = data.aws_canonical_user_id.this
  values = {
    id = "79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be"
  }
}

variables {
  domain_name = "Example.com"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this[0].bucket == "example.com"
    error_message = "The website bucket is named after the lower-case domain name."
  }

  assert {
    condition     = aws_s3_bucket.logs[0].bucket == "example.com-logs"
    error_message = "The log bucket is named after the website bucket."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].logging_config[0].prefix == "example.com/cloudfront/"
    error_message = "CloudFront access logs are written under the website bucket's prefix."
  }

  assert {
    condition     = contains(aws_cloudfront_distribution.this[0].aliases, "example.com")
    error_message = "The distribution answers for the domain name."
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "A certificate is requested by default."
  }

  assert {
    condition = anytrue([
      for grant in one(aws_s3_bucket_acl.logs[0].access_control_policy).grant :
      one(grant.grantee).id == "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0" && grant.permission == "FULL_CONTROL"
    ])
    error_message = "The log bucket's ACL grants CloudFront's log delivery account FULL_CONTROL."
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 0
    error_message = "S3 access logging is skipped, because the log bucket has Object Lock."
  }

  assert {
    condition = [
      for statement in jsondecode(data.aws_iam_policy_document.logs[0].json).Statement : statement.Sid
    ] == ["DenyInsecureTransport"]
    error_message = "The log bucket's policy only denies insecure transport."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].default_cache_behavior[0].response_headers_policy_id == "67f7725c-6f97-4210-82d7-5512b31e9d03"
    error_message = "The managed SecurityHeadersPolicy is attached by default."
  }

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.logs[0].rule).noncurrent_version_expiration[0].noncurrent_days == 1
    error_message = "Expired logs are deleted rather than kept as noncurrent versions."
  }
}

run "noncurrent_versions_expire" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this[0].rule).noncurrent_version_expiration[0].noncurrent_days == 30
    error_message = "Noncurrent versions of website objects expire after 30 days by default."
  }
}

run "noncurrent_versions_kept" {
  command = plan

  variables {
    noncurrent_version_expiration_days = null
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "The website bucket's lifecycle configuration is left unmanaged."
  }
}

run "noncurrent_versions_need_a_day" {
  command = plan

  variables {
    noncurrent_version_expiration_days = 0
  }

  expect_failures = [var.noncurrent_version_expiration_days]
}

run "log_bucket_without_object_lock" {
  command = plan

  variables {
    log_bucket_object_lock_enabled = false
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "example.com-logs"
    error_message = "S3 access logs go to the log bucket."
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_prefix == "example.com/s3/"
    error_message = "S3 access logs are written under the website bucket's prefix."
  }

  assert {
    condition = [
      for statement in jsondecode(data.aws_iam_policy_document.logs[0].json).Statement : statement.Sid
    ] == ["AllowS3ServerAccessLogs", "DenyInsecureTransport"]
    error_message = "The log bucket's policy lets S3 deliver server access logs."
  }

  assert {
    condition = one([
      for statement in jsondecode(data.aws_iam_policy_document.logs[0].json).Statement :
      statement.Resource if statement.Sid == "AllowS3ServerAccessLogs"
    ]) == "arn:aws:s3:::example.com-logs/example.com/s3/*"
    error_message = "S3 can only write under the S3 access log prefix."
  }
}

run "create_disabled" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = length(aws_s3_bucket.this) == 0 && length(aws_s3_bucket.logs) == 0
    error_message = "No buckets are created."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 0 && length(aws_acm_certificate.this) == 0
    error_message = "No distribution or certificate is created."
  }

  assert {
    condition     = output.bucket_name == "" && output.cloudfront_distribution_arn == ""
    error_message = "Outputs are empty."
  }
}

run "logging_disabled" {
  command = plan

  variables {
    enable_logging = false
  }

  assert {
    condition     = length(aws_s3_bucket.logs) == 0 && length(aws_s3_bucket_logging.this) == 0
    error_message = "No log bucket or S3 access logging is created."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this[0].logging_config) == 0
    error_message = "The distribution doesn't log."
  }
}

run "existing_log_bucket" {
  command = plan

  variables {
    create_log_bucket = false
    log_bucket_name   = "existing-logs"
  }

  assert {
    condition     = length(aws_s3_bucket.logs) == 0
    error_message = "No log bucket is created."
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "existing-logs"
    error_message = "S3 access logs go to the existing bucket."
  }

  assert {
    condition     = length(aws_s3_bucket_acl.logs) == 0 && length(aws_s3_bucket_policy.logs) == 0
    error_message = "The existing bucket's ACL and policy are left alone."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].logging_config[0].bucket == "existing-logs.s3.amazonaws.com"
    error_message = "CloudFront access logs go to the existing bucket."
  }
}

run "existing_log_bucket_requires_a_name" {
  command = plan

  variables {
    create_log_bucket = false
  }

  expect_failures = [var.log_bucket_name]
}

run "distribution_disabled" {
  command = plan

  variables {
    create_cloudfront_distribution = false
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 0
    error_message = "No distribution is created."
  }

  assert {
    condition = [
      for statement in jsondecode(data.aws_iam_policy_document.this[0].json).Statement : statement.Sid
    ] == ["DenyInsecureTransport"]
    error_message = "Without a distribution, the bucket policy only denies insecure transport."
  }

  assert {
    condition     = length(aws_s3_bucket_acl.logs) == 0
    error_message = "No ACL grant is needed without a distribution to write logs."
  }
}

run "existing_distribution" {
  command = plan

  variables {
    cloudfront_distribution_arn    = "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
    create_cloudfront_distribution = false
  }

  assert {
    condition = [
      for statement in jsondecode(data.aws_iam_policy_document.this[0].json).Statement : statement.Sid
    ] == ["AllowCloudFrontRead", "DenyInsecureTransport"]
    error_message = "The bucket policy grants the existing distribution access and denies insecure transport."
  }

  assert {
    condition = one([
      for statement in jsondecode(data.aws_iam_policy_document.this[0].json).Statement :
      statement.Condition.StringEquals["AWS:SourceArn"] if statement.Sid == "AllowCloudFrontRead"
    ]) == "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
    error_message = "Read access is limited to the existing distribution."
  }
}

run "existing_certificate" {
  command = plan

  variables {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    create_certificate  = false
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 0
    error_message = "No certificate is requested."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].viewer_certificate[0].acm_certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    error_message = "The distribution uses the existing certificate."
  }
}

run "existing_certificate_requires_an_arn" {
  command = plan

  variables {
    create_certificate = false
  }

  expect_failures = [var.acm_certificate_arn]
}

run "ordered_cache_behaviors_inherit_response_headers" {
  command = plan

  variables {
    cloudfront_additional_origins = {
      assets = {
        domain_name = "assets.example.com.s3.eu-west-1.amazonaws.com"
      }
    }

    cloudfront_ordered_cache_behaviors = [
      {
        path_pattern     = "/assets/*"
        target_origin_id = "assets"
      },
      {
        path_pattern               = "/api/*"
        response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
        target_origin_id           = "assets"
      },
    ]
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].ordered_cache_behavior[0].response_headers_policy_id == "67f7725c-6f97-4210-82d7-5512b31e9d03"
    error_message = "An ordered cache behavior without a policy inherits the distribution's."
  }

  assert {
    condition     = aws_cloudfront_distribution.this[0].ordered_cache_behavior[1].response_headers_policy_id == "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
    error_message = "An ordered cache behavior keeps its own policy."
  }
}

run "response_headers_disabled" {
  command = plan

  variables {
    cloudfront_response_headers_policy_id = null
  }

  assert {
    condition     = coalesce(aws_cloudfront_distribution.this[0].default_cache_behavior[0].response_headers_policy_id, "none") == "none"
    error_message = "No response headers policy is attached."
  }
}
