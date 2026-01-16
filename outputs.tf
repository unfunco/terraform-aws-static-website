// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = try(aws_s3_bucket.this[0].arn, "")
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = try(aws_s3_bucket.this[0].id, "")
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate."
  value       = try(aws_acm_certificate.this[0].arn, "")
}

output "certificate_domain_validation_options" {
  description = "The domain validation options of the ACM certificate."
  value       = try(aws_acm_certificate.this[0].domain_validation_options, [])
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID."
  value       = try(aws_cloudfront_distribution.this[0].id, "")
}

output "cloudfront_domain_name" {
  description = "The CloudFront domain name."
  value       = try(aws_cloudfront_distribution.this[0].domain_name, "")
}

output "cloudfront_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution."
  value       = try(aws_cloudfront_distribution.this[0].hosted_zone_id, "")
}