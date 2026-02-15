// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "acm_certificate_arn" {
  default     = ""
  description = "The ARN of an existing ACM certificate to use for the CloudFront distribution. Required when create_certificate is false."
  type        = string

  validation {
    condition     = !var.create || !var.create_cloudfront_distribution || var.create_certificate || trim(var.acm_certificate_arn) != ""
    error_message = "Set acm_certificate_arn when create_certificate is false and create_cloudfront_distribution is true."
  }
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

variable "cloudfront_allowed_methods" {
  default     = ["GET", "HEAD"]
  description = "The HTTP methods allowed by the CloudFront distribution."
  type        = list(string)
}

variable "cloudfront_additional_origins" {
  default     = {}
  description = "Additional origins to add to the CloudFront distribution, keyed by origin ID."
  type = map(object({
    connection_attempts               = optional(number, 3)
    connection_timeout                = optional(number, 10)
    custom_headers                    = optional(map(string), {})
    domain_name                       = string
    origin_access_control_id          = optional(string)
    origin_path                       = optional(string)
    use_default_origin_access_control = optional(bool, false)
  }))
}

variable "cloudfront_distribution_price_class" {
  default     = "PriceClass_All"
  description = "The price class for the CloudFront distribution."
  type        = string
}

variable "cloudfront_ordered_cache_behaviors" {
  default     = []
  description = "Additional ordered cache behaviors for path-based routing."
  type = list(object({
    allowed_methods            = optional(list(string), ["GET", "HEAD"])
    cache_policy_id            = optional(string, "658327ea-f89d-4fab-a63d-7e88639e58f6")
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    compress                   = optional(bool, true)
    origin_request_policy_id   = optional(string)
    path_pattern               = string
    response_headers_policy_id = optional(string)
    target_origin_id           = string
    viewer_protocol_policy     = optional(string, "redirect-to-https")
  }))
}

variable "cloudfront_response_headers_policy_id" {
  default     = null
  description = "The ID of a response headers policy to attach to the CloudFront distribution."
  type        = string
}

variable "cloudfront_retain_on_delete" {
  default     = false
  description = "Whether to retain the CloudFront distribution when deleting the resource."
  type        = bool
}

variable "cloudfront_web_acl_id" {
  default     = null
  description = "The ID of a WAF web ACL to associate with the CloudFront distribution."
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

variable "force_destroy" {
  default     = false
  description = "Whether to allow bucket deletion even when not empty."
  type        = bool
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

variable "log_bucket_object_lock_days" {
  default     = 365
  description = "Default retention period, in days, for object lock on the logging bucket."
  type        = number

  validation {
    condition     = !var.log_bucket_object_lock_enabled || var.log_bucket_object_lock_days >= 1
    error_message = "Set log_bucket_object_lock_days to at least 1 when log_bucket_object_lock_enabled is true."
  }
}

variable "log_bucket_object_lock_enabled" {
  default     = true
  description = "Whether to enable S3 Object Lock on the logging bucket. This only applies at bucket creation time."
  type        = bool
}

variable "log_bucket_object_lock_mode" {
  default     = "GOVERNANCE"
  description = "Default object lock retention mode for the logging bucket. Valid values are GOVERNANCE or COMPLIANCE."
  type        = string

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.log_bucket_object_lock_mode)
    error_message = "Set log_bucket_object_lock_mode to GOVERNANCE or COMPLIANCE."
  }
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
