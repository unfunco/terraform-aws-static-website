// Copyright © 2023 Daniel Morris
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

locals {
  bucket_name = var.bucket_name == "" ? local.domain_name : var.bucket_name
  domain_name = lower(var.domain_name)
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name == "" ? local.domain_name : var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket" "logs" {
  count = var.enable_logging && var.create_log_bucket ? 1 : 0

  bucket        = var.bucket_name_logs == "" ? join("-", [aws_s3_bucket.this.id, "logs"]) : var.bucket_name_logs
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_acl" "this" {
  acl    = "private"
  bucket = aws_s3_bucket.this.id
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.bucket_name_logs == "" ? join("-", [aws_s3_bucket.this.id, "logs"]) : var.bucket_name_logs
  target_prefix = "s3-logs/"
}

resource "aws_s3_bucket_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.this.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  error_document {
    key = var.error_document
  }

  index_document {
    suffix = var.index_document
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  count = var.create_cloudfront_distribution ? 1 : 0

  comment = "CloudFront OAI for the ${aws_s3_bucket.this.id} S3 bucket."
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create_cloudfront_distribution ? 1 : 0

  comment             = "CloudFront distribution for ${aws_s3_bucket.this.id}."
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
    target_origin_id       = aws_s3_bucket.this.id
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
      bucket = var.bucket_name
      prefix = "cloudfront-logs/"
    }
  }

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.this.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this[0].cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
