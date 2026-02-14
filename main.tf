// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  bucket_name = var.bucket_name == "" ? local.domain_name : var.bucket_name
  domain_name = lower(var.domain_name)

  log_bucket_id            = var.create && var.create_log_bucket ? aws_s3_bucket.logs[0].id : var.log_bucket_name
  log_bucket_domain        = var.create && var.create_log_bucket ? aws_s3_bucket.logs[0].bucket_regional_domain_name : "${var.log_bucket_name}.s3.${data.aws_partition.this[0].dns_suffix}"
  log_bucket_target_prefix = var.log_bucket_target_prefix == "" ? local.bucket_name : var.log_bucket_target_prefix
}

resource "aws_acm_certificate" "this" {
  count  = var.create && var.create_certificate ? 1 : 0
  region = "us-east-1"

  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "this" {
  count = var.create ? 1 : 0

  bucket        = var.bucket_name == "" ? local.domain_name : var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "this" {
  count = var.create && var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.this[0].id
  target_bucket = local.log_bucket_id
  target_prefix = "${local.log_bucket_target_prefix}/s3/"
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_object" "error_document" {
  count = var.create && var.create_default_documents ? 1 : 0

  bucket       = aws_s3_bucket.this[0].id
  content_type = "text/html"
  key          = var.error_document

  content = <<-EOF
    <!DOCTYPE html>
    <html dir="ltr" lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="initial-scale=1.0,width=device-width">
      <title>Whoops</title>
    </head>
    <body>
      <p>An error occurred.</p>
    </body>
    </html>
  EOF

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_object" "index_document" {
  count = var.create && var.create_default_documents ? 1 : 0

  bucket       = aws_s3_bucket.this[0].id
  content_type = "text/html"
  key          = var.index_document

  content = <<-EOF
    <!DOCTYPE html>
    <html dir="ltr" lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="initial-scale=1.0,width=device-width">
      <title>Booyah achieved!</title>
    </head>
    <body>
      <p>Your static website has been successfully created!</p>
    </body>
    </html>
  EOF

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket        = var.log_bucket_name == "" ? join("-", [aws_s3_bucket.this[0].id, "logs"]) : var.log_bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.logs[0].id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "logs"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  name                              = aws_s3_bucket.this[0].id
  description                       = "OAC for ${local.domain_name}."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  aliases             = [local.domain_name]
  comment             = "CloudFront distribution for ${aws_s3_bucket.this[0].id}."
  default_root_object = var.index_document
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_distribution_price_class
  provider            = aws.us_east_1
  retain_on_delete    = var.cloudfront_retain_on_delete
  tags                = var.tags
  wait_for_deployment = true
  web_acl_id          = var.cloudfront_web_acl_id

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 404
    response_page_path    = "/${var.error_document}"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
  }

  default_cache_behavior {
    allowed_methods            = var.cloudfront_allowed_methods
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    response_headers_policy_id = var.cloudfront_response_headers_policy_id
    target_origin_id           = aws_s3_bucket.this[0].id
    viewer_protocol_policy     = "redirect-to-https"
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_ordered_cache_behaviors

    content {
      allowed_methods            = ordered_cache_behavior.value.allowed_methods
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      cached_methods             = ordered_cache_behavior.value.cached_methods
      compress                   = ordered_cache_behavior.value.compress
      origin_request_policy_id   = try(ordered_cache_behavior.value.origin_request_policy_id, null)
      path_pattern               = ordered_cache_behavior.value.path_pattern
      response_headers_policy_id = try(ordered_cache_behavior.value.response_headers_policy_id, var.cloudfront_response_headers_policy_id)
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []

    content {
      bucket = local.log_bucket_domain
      prefix = "${local.log_bucket_target_prefix}/cloudfront/"
    }
  }

  origin {
    domain_name              = aws_s3_bucket.this[0].bucket_regional_domain_name
    origin_id                = aws_s3_bucket.this[0].id
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  dynamic "origin" {
    for_each = var.cloudfront_additional_origins

    content {
      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout
      domain_name         = origin.value.domain_name
      origin_id           = origin.key
      origin_path         = try(origin.value.origin_path, null)
      origin_access_control_id = origin.value.use_default_origin_access_control ? aws_cloudfront_origin_access_control.this[0].id : try(
        origin.value.origin_access_control_id,
        null,
      )

      dynamic "custom_header" {
        for_each = origin.value.custom_headers

        content {
          name  = custom_header.key
          value = custom_header.value
        }
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.create_certificate ? aws_acm_certificate.this[0].arn : var.acm_certificate_arn
    cloudfront_default_certificate = !var.create_certificate
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}
