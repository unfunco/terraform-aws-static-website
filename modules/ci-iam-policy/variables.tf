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

variable "required_resource_tags" {
  default     = {}
  description = "Required aws:ResourceTag conditions for content permissions. Keys are tag names and values are required tag values."
  type        = map(string)
}
