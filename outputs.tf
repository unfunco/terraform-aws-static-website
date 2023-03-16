output "bucket_arn" {
  description = ""
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = ""
  value       = aws_s3_bucket.this.id
}

output "cloudfront_distribution_id" {
  description = ""
  value       = aws_cloudfront_distribution.this[0].id
}

output "cloudfront_domain_name" {
  description = ""
  value       = aws_cloudfront_distribution.this[0].domain_name
}
