// SPDX-FileCopyrightText: 2023 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "bucket_name" {
  default     = ""
  description = "Name of the S3 bucket that will store the website."
  type        = string
}

variable "bucket_name_logs" {
  default     = ""
  description = "Name of the S3 bucket that will store logs."
  type        = string
}

variable "create" {
  default     = true
  description = "Enable/disable the creation of all resources."
  type        = bool
}

variable "create_certificate" {
  default     = true
  description = "Enable/disable the creation of an ACM certificate."
  type        = bool
}

variable "create_cloudfront_distribution" {
  default     = true
  description = "Enable/disable the creation of a CloudFront distribution."
  type        = bool
}

variable "create_log_bucket" {
  default     = true
  description = "Enable/disable the creation of a log bucket."
  type        = bool
}

variable "domain_name" {
  description = "Domain name of the website."
  type        = string
}

variable "enable_logging" {
  default     = true
  description = "Enable/disable logging on the S3 bucket."
  type        = bool
}

variable "enable_versioning" {
  default     = true
  description = "Enable/disable versioning on the S3 bucket."
  type        = bool
}

variable "error_document" {
  default     = "error.html"
  description = "Document returned when a 4xx error occurs."
  type        = string
}

variable "index_document" {
  default     = "index.html"
  description = "Document returned for directory requests."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to apply to all applicable resources."
  type        = map(string)
}
