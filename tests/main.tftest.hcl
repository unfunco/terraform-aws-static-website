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

run "pretty_urls_disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_cloudfront_function.pretty_urls) == 0
    error_message = "No function is created by default."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this[0].default_cache_behavior[0].function_association) == 0
    error_message = "The default cache behavior has no function by default."
  }
}

run "pretty_urls_directory" {
  command = plan

  variables {
    cloudfront_additional_origins = {
      api = {
        domain_name = "api.example.com"
      }
    }

    cloudfront_ordered_cache_behaviors = [
      {
        path_pattern     = "/docs/*"
        target_origin_id = "example.com"
      },
      {
        path_pattern     = "/api/*"
        target_origin_id = "api"
      },
    ]

    pretty_urls = "directory"
  }

  assert {
    condition     = aws_cloudfront_function.pretty_urls[0].name == "example-com-pretty-urls"
    error_message = "The function is named after the bucket."
  }

  assert {
    condition     = strcontains(aws_cloudfront_function.pretty_urls[0].code, "var indexDocument = \"index.html\";") && strcontains(aws_cloudfront_function.pretty_urls[0].code, "var style = \"directory\";")
    error_message = "The function is rendered with the index document and style."
  }

  assert {
    condition     = one(aws_cloudfront_distribution.this[0].default_cache_behavior[0].function_association).event_type == "viewer-request"
    error_message = "The function runs on viewer requests for the default cache behavior."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this[0].ordered_cache_behavior[0].function_association) == 1
    error_message = "An ordered cache behavior for the website bucket runs the function."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this[0].ordered_cache_behavior[1].function_association) == 0
    error_message = "An ordered cache behavior for another origin doesn't."
  }
}

run "pretty_urls_file" {
  command = plan

  variables {
    index_document = "home.html"
    pretty_urls    = "file"
  }

  assert {
    condition     = strcontains(aws_cloudfront_function.pretty_urls[0].code, "var indexDocument = \"home.html\";") && strcontains(aws_cloudfront_function.pretty_urls[0].code, "var style = \"file\";")
    error_message = "The function is rendered with the index document and style."
  }
}

run "pretty_urls_name_is_truncated" {
  command = plan

  variables {
    domain_name    = "a-very-long-subdomain-name-for-testing-the-module.example.co.uk"
    enable_logging = false
    pretty_urls    = "directory"
  }

  assert {
    condition     = length(aws_cloudfront_function.pretty_urls[0].name) <= 64
    error_message = "Function names are limited to 64 characters."
  }
}

run "pretty_urls_rejects_unknown_styles" {
  command = plan

  variables {
    pretty_urls = "extensionless"
  }

  expect_failures = [var.pretty_urls]
}

run "route53_disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_route53_record.this) == 0 && length(aws_route53_record.certificate_validation) == 0 && length(aws_acm_certificate_validation.this) == 0
    error_message = "No DNS records are created without a hosted zone."
  }
}

run "route53" {
  command = plan

  variables {
    route53_zone_id = "Z0123456789ABCDEFGHIJ"
  }

  assert {
    condition     = keys(aws_route53_record.certificate_validation) == ["example.com"]
    error_message = "The certificate is validated with a record in the zone."
  }

  assert {
    condition     = aws_route53_record.certificate_validation["example.com"].allow_overwrite
    error_message = "The validation record can be shared with other certificates for the domain."
  }

  assert {
    condition     = length(aws_acm_certificate_validation.this) == 1
    error_message = "The module waits for the certificate to be issued."
  }

  assert {
    condition     = toset(keys(aws_route53_record.this)) == toset(["A", "AAAA"])
    error_message = "A and AAAA alias records are created."
  }

  assert {
    condition     = aws_route53_record.this["AAAA"].name == "example.com" && aws_route53_record.this["AAAA"].zone_id == "Z0123456789ABCDEFGHIJ"
    error_message = "The alias records are for the domain name in the zone."
  }
}

run "route53_with_existing_certificate" {
  command = plan

  variables {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    create_certificate  = false
    route53_zone_id     = "Z0123456789ABCDEFGHIJ"
  }

  assert {
    condition     = length(aws_route53_record.certificate_validation) == 0 && length(aws_acm_certificate_validation.this) == 0
    error_message = "An existing certificate isn't validated."
  }

  assert {
    condition     = length(aws_route53_record.this) == 2
    error_message = "Alias records are still created."
  }
}

run "route53_rejects_empty_zone_ids" {
  command = plan

  variables {
    route53_zone_id = " "
  }

  expect_failures = [var.route53_zone_id]
}
