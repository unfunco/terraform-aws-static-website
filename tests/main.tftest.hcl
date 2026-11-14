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
    condition     = aws_s3_bucket_logging.this[0].target_prefix == "example.com/s3/"
    error_message = "S3 access logs are written under the website bucket's prefix."
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
    condition     = length(aws_s3_bucket_policy.this) == 0
    error_message = "No bucket policy is created without a distribution to grant access to."
  }
}

run "existing_distribution" {
  command = plan

  variables {
    cloudfront_distribution_arn    = "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
    create_cloudfront_distribution = false
  }

  assert {
    condition     = length(aws_s3_bucket_policy.this) == 1
    error_message = "The bucket policy grants the existing distribution access."
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
