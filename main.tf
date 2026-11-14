// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  bucket_name = var.bucket_name == "" ? local.domain_name : var.bucket_name
  domain_name = lower(var.domain_name)

  create_cloudfront_distribution = var.create && var.create_cloudfront_distribution
  create_log_bucket              = var.create && var.enable_logging && var.create_log_bucket
  create_pretty_urls_function    = local.create_cloudfront_distribution && var.pretty_urls != null

  create_dns_records   = local.create_cloudfront_distribution && var.route53_zone_id != null
  validate_certificate = var.create && var.create_certificate && var.route53_zone_id != null

  // CloudFront's legacy standard logging writes with the awslogsdelivery
  // account, which needs a grant in the log bucket's ACL.
  create_log_bucket_acl = local.create_log_bucket && local.create_cloudfront_distribution

  // S3 can't deliver server access logs to a bucket with Object Lock.
  enable_s3_access_logging = var.create && var.enable_logging && !(local.create_log_bucket && var.log_bucket_object_lock_enabled)

  allow_s3_access_logs = local.create_log_bucket && local.enable_s3_access_logging

  // The website bucket grants read access to a distribution, either the
  // module's or an existing one.
  grant_cloudfront_access = var.create_cloudfront_distribution || var.cloudfront_distribution_arn != ""

  log_bucket_name = var.log_bucket_name == "" ? "${local.bucket_name}-logs" : var.log_bucket_name

  log_bucket_id = local.create_log_bucket ? aws_s3_bucket.logs[0].bucket : var.log_bucket_name
  log_bucket_domain = local.create_log_bucket ? aws_s3_bucket.logs[0].bucket_regional_domain_name : format(
    "%s.s3.%s",
    var.log_bucket_name,
    try(data.aws_partition.this[0].dns_suffix, "amazonaws.com"),
  )
  log_bucket_target_prefix = var.log_bucket_target_prefix == "" ? local.bucket_name : var.log_bucket_target_prefix

  certificate_validation_options = local.validate_certificate ? {
    for option in aws_acm_certificate.this[0].domain_validation_options : option.domain_name => option
  } : {}

  // The distribution waits for the certificate to be issued when the module
  // validates it, because CloudFront rejects a certificate pending validation.
  certificate_arn = !var.create_certificate ? var.acm_certificate_arn : (
    local.validate_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : one(aws_acm_certificate.this[*].arn)
  )
}

resource "aws_acm_certificate" "this" {
  count  = var.create && var.create_certificate ? 1 : 0
  region = "us-east-1"

  domain_name       = local.domain_name
  tags              = var.tags
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = local.validate_certificate ? toset([local.domain_name]) : toset([])

  // ACM gives every certificate for the same domain in an account the same
  // validation record, so another certificate may have created it already.
  allow_overwrite = true
  name            = local.certificate_validation_options[each.key].resource_record_name
  records         = [local.certificate_validation_options[each.key].resource_record_value]
  ttl             = 60
  type            = local.certificate_validation_options[each.key].resource_record_type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "this" {
  count  = local.validate_certificate ? 1 : 0
  region = "us-east-1"

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_s3_bucket" "this" {
  count = var.create ? 1 : 0

  bucket        = local.bucket_name
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
  count      = local.enable_s3_access_logging ? 1 : 0
  depends_on = [aws_s3_bucket_policy.logs]

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

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create && var.noncurrent_version_expiration_days != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "website"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    // Deploys that delete objects leave delete markers behind, which can
    // go once the versions under them have expired.
    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
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
  count = local.create_log_bucket ? 1 : 0

  bucket              = local.log_bucket_name
  force_destroy       = var.force_destroy
  object_lock_enabled = var.log_bucket_object_lock_enabled
  tags                = var.tags
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = local.create_log_bucket ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.logs[0].id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "logs"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 365
    }

    // The bucket is versioned, so expiring a log only hides it behind a
    // delete marker. Removing the noncurrent version deletes it.
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_acl" "logs" {
  count      = local.create_log_bucket_acl ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs[0].id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.this[0].id
    }

    grant {
      permission = "FULL_CONTROL"

      grantee {
        id   = data.aws_canonical_user_id.this[0].id
        type = "CanonicalUser"
      }
    }

    grant {
      permission = "FULL_CONTROL"

      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.this[0].id
        type = "CanonicalUser"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count      = local.create_log_bucket ? 1 : 0
  depends_on = [aws_s3_bucket_public_access_block.logs]

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json
}

resource "aws_s3_bucket_versioning" "logs" {
  count = local.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "logs" {
  count      = local.create_log_bucket && var.log_bucket_object_lock_enabled ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.logs]

  bucket              = aws_s3_bucket.logs[0].id
  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      days = var.log_bucket_object_lock_days
      mode = var.log_bucket_object_lock_mode
    }
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = local.create_cloudfront_distribution ? 1 : 0

  name                              = local.bucket_name
  description                       = "OAC for ${local.domain_name}."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "pretty_urls" {
  count = local.create_pretty_urls_function ? 1 : 0

  comment = "Pretty URLs for ${local.domain_name}."
  name    = substr("${replace(local.bucket_name, ".", "-")}-pretty-urls", 0, 64)
  publish = true
  runtime = "cloudfront-js-2.0"

  code = templatefile("${path.module}/templates/pretty-urls.js.tftpl", {
    index_document = var.index_document
    style          = var.pretty_urls
  })
}

resource "aws_cloudfront_distribution" "this" {
  count = local.create_cloudfront_distribution ? 1 : 0

  // CloudFront checks the log bucket's ACL when logging is configured.
  depends_on = [aws_s3_bucket_acl.logs]

  aliases             = [local.domain_name]
  comment             = "CloudFront distribution for ${local.bucket_name}."
  default_root_object = var.index_document
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_distribution_price_class
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
    target_origin_id           = local.bucket_name
    viewer_protocol_policy     = "redirect-to-https"

    dynamic "function_association" {
      for_each = local.create_pretty_urls_function ? [aws_cloudfront_function.pretty_urls[0].arn] : []

      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
      }
    }
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
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id != null ? ordered_cache_behavior.value.response_headers_policy_id : var.cloudfront_response_headers_policy_id
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy

      // Behaviors that serve the website bucket rewrite URLs the same way
      // as the default behavior.
      dynamic "function_association" {
        for_each = local.create_pretty_urls_function && ordered_cache_behavior.value.target_origin_id == local.bucket_name ? [aws_cloudfront_function.pretty_urls[0].arn] : []

        content {
          event_type   = "viewer-request"
          function_arn = function_association.value
        }
      }
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
    origin_id                = local.bucket_name
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
    acm_certificate_arn            = local.certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "this" {
  for_each = local.create_dns_records ? toset(["A", "AAAA"]) : toset([])

  name    = local.domain_name
  type    = each.key
  zone_id = var.route53_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.this[0].domain_name
    zone_id                = aws_cloudfront_distribution.this[0].hosted_zone_id
  }
}
