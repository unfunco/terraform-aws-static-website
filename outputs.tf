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

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate."
  value       = aws_acm_certificate.this[0].arn
}

output "certificate_domain_validation_options" {
  description = "The domain validation options of the ACM certificate."
  value       = aws_acm_certificate.this[0].domain_validation_options
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this[0].id
}

output "cloudfront_domain_name" {
  description = "The CloudFront domain name."
  value       = aws_cloudfront_distribution.this[0].domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this[0].hosted_zone_id
}
