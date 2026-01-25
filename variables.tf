// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "acm_certificate_arn" {
  default     = ""
  description = "The ARN of an existing ACM certificate to use for the CloudFront distribution. Required when create_certificate is false."
  type        = string
}

variable "bucket_name" {
  default     = ""
  description = "The name of the S3 bucket for storing website content."
  type        = string
}

variable "cloudfront_distribution_arn" {
  default     = ""
  description = "The ARN of an existing CloudFront distribution to use for the S3 bucket policy."
  type        = string
}

variable "cloudfront_distribution_price_class" {
  default     = "PriceClass_All"
  description = "The price class for the CloudFront distribution."
  type        = string
}

variable "create" {
  default     = true
  description = "Whether to create resources."
  type        = bool
}

variable "create_certificate" {
  default     = true
  description = "Whether to create an ACM certificate."
  type        = bool
}

variable "create_cloudfront_distribution" {
  default     = true
  description = "Whether to create a CloudFront distribution."
  type        = bool
}

variable "create_default_documents" {
  default     = true
  description = "Whether to create default index and error documents."
  type        = bool
}

variable "create_log_bucket" {
  default     = true
  description = "Whether to create a dedicated logging bucket."
  type        = bool
}

variable "domain_name" {
  description = "The domain name for the website."
  type        = string
}

variable "enable_logging" {
  default     = true
  description = "Whether to enable access logging for S3 and CloudFront."
  type        = bool
}

variable "enable_versioning" {
  default     = true
  description = "Whether to enable versioning on the S3 bucket."
  type        = bool
}

variable "error_document" {
  default     = "error.html"
  description = "The path to the error document returned for 4xx errors."
  type        = string
}

variable "index_document" {
  default     = "index.html"
  description = "The path to the index document returned for directory requests."
  type        = string
}

variable "log_bucket_name" {
  default     = ""
  description = "The name of the S3 bucket for storing access logs."
  type        = string
}

variable "log_bucket_target_prefix" {
  default     = ""
  description = "The prefix for log objects in the logging bucket."
  type        = string
}

variable "tags" {
  default     = {}
  description = "The tags to apply to all taggable resources."
  type        = map(string)
}
