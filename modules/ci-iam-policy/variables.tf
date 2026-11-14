// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "attach_content_permissions" {
  default     = true
  description = "Whether to attach permissions for deploying content to the S3 bucket."
  type        = bool
}

variable "attach_infrastructure_permissions" {
  default     = false
  description = "Whether to attach permissions for managing the underlying infrastructure."
  type        = bool
}

variable "bucket_name" {
  description = "The name of the S3 bucket for the static website."
  type        = string
}

variable "log_bucket_name" {
  default     = ""
  description = "The name of the S3 bucket used for access logs. Leave empty to use the bucket name followed by -logs, as the website module does."
  type        = string
}

variable "cloudfront_distribution_arn" {
  default     = "*"
  description = "The ARN of the CloudFront distribution for scoping cache invalidation permissions."
  type        = string
}

variable "create" {
  default     = true
  description = "Whether to create resources."
  type        = bool
}

variable "route53_zone_id" {
  default     = null
  description = "The ID of the Route 53 hosted zone passed to the website module, if any. Infrastructure permissions then include managing records in that zone."
  type        = string
}

variable "required_resource_tags" {
  default     = {}
  description = "Tags the CloudFront distribution must have for the cache invalidation permission, as aws:ResourceTag conditions. Keys are tag names and values are required tag values. The S3 permissions are scoped to the bucket's ARN instead, because S3 only evaluates resource tags on buckets with ABAC enabled."
  type        = map(string)
}
