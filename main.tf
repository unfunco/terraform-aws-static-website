// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  bucket_name = var.bucket_name == "" ? local.domain_name : var.bucket_name
  domain_name = lower(var.domain_name)
}

resource "random_pet" "secret_user_agent" {
  count = var.create ? 1 : 0

  length    = 4
  separator = "-"
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
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_acl" "this" {
  count = var.create ? 1 : 0

  acl    = "private"
  bucket = aws_s3_bucket.this[0].id
}

resource "aws_s3_bucket_logging" "this" {
  count = var.create && var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.this[0].id
  target_bucket = var.bucket_name_logs == "" ? aws_s3_bucket.logs[0].id : var.bucket_name_logs
  target_prefix = "s3/"
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

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  error_document {
    key = var.error_document
  }

  index_document {
    suffix = var.index_document
  }
}

resource "aws_s3_bucket" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket        = var.bucket_name_logs == "" ? join("-", [aws_s3_bucket.this[0].id, "logs"]) : var.bucket_name_logs
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_acl" "logs" {
  count = var.create && var.enable_logging && var.create_log_bucket ? 1 : 0

  acl    = "log-delivery-write"
  bucket = aws_s3_bucket.logs[0].id
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

resource "aws_cloudfront_distribution" "this" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  aliases             = [local.domain_name]
  comment             = "CloudFront distribution for ${aws_s3_bucket.this[0].id}."
  default_root_object = var.index_document
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  provider            = aws.us_east_1
  retain_on_delete    = true
  tags                = var.tags
  wait_for_deployment = true

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 300
    max_ttl                = 3600
    min_ttl                = 0
    target_origin_id       = aws_s3_bucket.this[0].id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []

    content {
      bucket = aws_s3_bucket.logs[0].bucket_regional_domain_name
      prefix = "cloudfront/"
    }
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.this[0].website_endpoint
    origin_id   = aws_s3_bucket.this[0].id

    custom_header {
      name  = "User-Agent"
      value = random_pet.secret_user_agent[0].id
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.this[0].arn
    cloudfront_default_certificate = !var.create_certificate
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}
