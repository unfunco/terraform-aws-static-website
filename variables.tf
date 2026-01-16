// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "bucket_name" {
  default     = ""
  description = "The name of the S3 bucket that will store the website."
  type        = string
}

variable "bucket_name_logs" {
  default     = null
  description = "The name of the S3 bucket that will store logs."
  type        = string
}

variable "create_certificate" {
  default     = true
  description = "A flag to enable/disable the creation of an ACM certificate."
  type        = bool
}

variable "create_cloudfront_distribution" {
  default     = true
  description = "A flag to enable/disable the creation of a CloudFront distribution."
  type        = bool
}

variable "create_log_bucket" {
  default     = true
  description = "A flag to enable/disable the creation of a log bucket."
  type        = bool
}

variable "domain_name" {
  description = "The domain name of the website."
  type        = string
}

variable "enable_logging" {
  default     = true
  description = "A flag to enable/disable logging on the S3 bucket."
  type        = bool
}

variable "enable_versioning" {
  default     = true
  description = "A flag to enable/disable versioning on the S3 bucket."
  type        = bool
}

variable "error_document" {
  default     = "error.html"
  description = "The document returned when a 4xx error occurs."
  type        = string
}

variable "index_document" {
  default     = "index.html"
  description = "The document returned for directory requests."
  type        = string
}

variable "tags" {
  default     = {}
  description = "A map of tags to apply to all applicable resources."
  type        = map(string)
}
