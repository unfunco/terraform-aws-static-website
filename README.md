# terraform-aws-static-website

[![CI](https://github.com/unfunco/terraform-aws-static-website/actions/workflows/ci.yaml/badge.svg)](https://github.com/unfunco/terraform-aws-static-website/actions/workflows/ci.yaml)
[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-unfunco%2Fstatic--website-blue?logo=terraform)](https://registry.terraform.io/modules/unfunco/static-website/aws)
[![License](https://img.shields.io/github/license/unfunco/terraform-aws-static-website)](LICENSE.md)

Terraform module for [AWS] static website hosting with [S3], [CloudFront] CDN,
automatic SSL/TLS certificates, HTTP/3, IPv6, and secure defaults using
[Origin Access Control] (OAC).

## Getting started

### Requirements

- [Terraform] 1.14+ and the [AWS provider] 6.0+

### Installation and usage

<!-- x-release-please-start-version -->

```terraform
module "website" {
  source  = "unfunco/static-website/aws"
  version = "0.6.0"

  domain_name = "unfun.co"
}
```

The module uses the AWS provider configuration that it inherits from the
calling module, so the S3 buckets are created in that provider's region and
account. The ACM certificate is always requested in us-east-1, because
CloudFront only accepts certificates from that region.

#### Pretty URLs

CloudFront requests objects from S3 by their exact key, and only serves the
index document at the root of the site, so a page built as `about/index.html`
can only be reached at `/about/index.html`. Set `pretty_urls` to have a
CloudFront Function map extensionless paths onto your HTML files, in the style
your site generator writes them:

| `pretty_urls`    | Pages built as     | `/about/`                 | `/about`               |
| ---------------- | ------------------ | ------------------------- | ---------------------- |
| `null` (default) |                    | 404                       | 404                    |
| `"directory"`    | `about/index.html` | serves `about/index.html` | redirects to `/about/` |
| `"file"`         | `about.html`       | serves `about/index.html` | serves `about.html`    |

Eleventy, Hugo and Astro write `about/index.html` by default, while Next.js
and SvelteKit static exports write `about.html`. Paths with a file extension,
and anything under `/.well-known/`, are served as they are. The function also
runs for ordered cache behaviors whose origin is the website bucket.

#### DNS

CloudFront won't accept a certificate until it has been issued. Set
`route53_zone_id` to the hosted zone for `domain_name`, and the module creates
the certificate's validation record, waits for the certificate to be issued
before creating the distribution, and points A and AAAA alias records at the
distribution.

Without a hosted zone, the first apply fails with `InvalidViewerCertificate`.
Create the record from the `certificate_domain_validation_options` output with
your DNS provider, wait for the certificate to be issued, and apply again.

Terraform won't overwrite A or AAAA records that already exist. To hand
existing records to the module, import them:

```terraform
import {
  to = module.website.aws_route53_record.this["A"]
  id = "Z0123456789ABCDEFGHIJ_example.com_A"
}
```

#### IAM

Use the bundled `modules/ci-iam-policy` module to generate an inline IAM policy
document for your CI role. The module has two boolean inputs to control which
permissions are included, `attach_content_permissions` is enough for deploy jobs
that sync website content and invalidate CloudFront, while
`attach_infrastructure_permissions` is for Terraform jobs that create or update
AWS resources. When the website module manages DNS records, pass the same
`route53_zone_id` to the policy module, so Terraform jobs can change records in
that zone.

```terraform
module "ci_iam_policy_deploy" {
  source  = "unfunco/static-website/aws//modules/ci-iam-policy"
  version = "0.6.0"

  attach_content_permissions        = true
  attach_infrastructure_permissions = false
  bucket_name                       = module.website.bucket_name
  cloudfront_distribution_arn       = module.website.cloudfront_distribution_arn
}
```

<!-- x-release-please-end -->

```terraform
module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "3.1.0"

  github_subjects = ["unfunco/unfun.co"]

  iam_role_inline_policies = {
    deploy = module.ci_iam_policy_deploy.policy_document
  }
}
```

<!-- BEGIN_TF_DOCS -->

### Resources

| Name                                                                                                                                                                           | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                                                        | resource    |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation)                                  | resource    |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)                                        | resource    |
| [aws_cloudfront_function.pretty_urls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function)                                         | resource    |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control)                      | resource    |
| [aws_route53_record.certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                        | resource    |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                                          | resource    |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                                    | resource    |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                                    | resource    |
| [aws_s3_bucket_acl.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl)                                                            | resource    |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)                    | resource    |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)                    | resource    |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging)                                                    | resource    |
| [aws_s3_bucket_object_lock_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration)                | resource    |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls)                              | resource    |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls)                              | resource    |
| [aws_s3_bucket_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                                                      | resource    |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                                                      | resource    |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)                            | resource    |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)                            | resource    |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                                              | resource    |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                                              | resource    |
| [aws_s3_object.error_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                                          | resource    |
| [aws_s3_object.index_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                                          | resource    |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                                     | data source |
| [aws_canonical_user_id.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id)                                                 | data source |
| [aws_cloudfront_log_delivery_canonical_user_id.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_log_delivery_canonical_user_id) | data source |
| [aws_iam_policy_document.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                                             | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                                             | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                                                                 | data source |

### Inputs

| Name                                  | Description                                                                                                                                                                                                                                                                                                                                                                                                               | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Default                                  | Required |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | :------: |
| acm_certificate_arn                   | The ARN of an existing ACM certificate to use for the CloudFront distribution. Required when create_certificate is false.                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                                     |    no    |
| bucket_name                           | The name of the S3 bucket for storing website content.                                                                                                                                                                                                                                                                                                                                                                    | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                                     |    no    |
| cloudfront_additional_origins         | Additional origins to add to the CloudFront distribution, keyed by origin ID.                                                                                                                                                                                                                                                                                                                                             | `map(object({ connection_attempts = optional(number, 3) connection_timeout = optional(number, 10) custom_headers = optional(map(string), {}) domain_name = string origin_access_control_id = optional(string) origin_path = optional(string) use_default_origin_access_control = optional(bool, false) }))`                                                                                                                                                | `{}`                                     |    no    |
| cloudfront_allowed_methods            | The HTTP methods allowed by the CloudFront distribution.                                                                                                                                                                                                                                                                                                                                                                  | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                             | `[ "GET", "HEAD" ]`                      |    no    |
| cloudfront_distribution_arn           | The ARN of an existing CloudFront distribution to use for the S3 bucket policy.                                                                                                                                                                                                                                                                                                                                           | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                                     |    no    |
| cloudfront_distribution_price_class   | The price class for the CloudFront distribution.                                                                                                                                                                                                                                                                                                                                                                          | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"PriceClass_All"`                       |    no    |
| cloudfront_ordered_cache_behaviors    | Additional ordered cache behaviors for path-based routing.                                                                                                                                                                                                                                                                                                                                                                | `list(object({ allowed_methods = optional(list(string), ["GET", "HEAD"]) cache_policy_id = optional(string, "658327ea-f89d-4fab-a63d-7e88639e58f6") cached_methods = optional(list(string), ["GET", "HEAD"]) compress = optional(bool, true) origin_request_policy_id = optional(string) path_pattern = string response_headers_policy_id = optional(string) target_origin_id = string viewer_protocol_policy = optional(string, "redirect-to-https") }))` | `[]`                                     |    no    |
| cloudfront_response_headers_policy_id | The ID of a response headers policy to attach to the CloudFront distribution, and to ordered cache behaviors that don't set their own. Defaults to the AWS managed SecurityHeadersPolicy, which adds HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy and X-XSS-Protection headers. Set to null to add no headers.                                                                                          | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"67f7725c-6f97-4210-82d7-5512b31e9d03"` |    no    |
| cloudfront_retain_on_delete           | Whether to retain the CloudFront distribution when deleting the resource.                                                                                                                                                                                                                                                                                                                                                 | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `false`                                  |    no    |
| cloudfront_web_acl_id                 | The ID of a WAF web ACL to associate with the CloudFront distribution.                                                                                                                                                                                                                                                                                                                                                    | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `null`                                   |    no    |
| create                                | Whether to create resources.                                                                                                                                                                                                                                                                                                                                                                                              | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| create_certificate                    | Whether to create an ACM certificate.                                                                                                                                                                                                                                                                                                                                                                                     | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| create_cloudfront_distribution        | Whether to create a CloudFront distribution.                                                                                                                                                                                                                                                                                                                                                                              | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| create_default_documents              | Whether to create default index and error documents.                                                                                                                                                                                                                                                                                                                                                                      | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| create_log_bucket                     | Whether to create a dedicated logging bucket.                                                                                                                                                                                                                                                                                                                                                                             | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| domain_name                           | The domain name for the website.                                                                                                                                                                                                                                                                                                                                                                                          | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a                                      |   yes    |
| enable_logging                        | Whether to enable access logging for CloudFront and S3. S3 server access logs are skipped when the module creates the log bucket with Object Lock, because S3 can't deliver them to such a bucket.                                                                                                                                                                                                                        | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| enable_versioning                     | Whether to enable versioning on the S3 bucket.                                                                                                                                                                                                                                                                                                                                                                            | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| error_document                        | The path to the error document returned for 4xx errors.                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"error.html"`                           |    no    |
| force_destroy                         | Whether to allow bucket deletion even when not empty.                                                                                                                                                                                                                                                                                                                                                                     | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `false`                                  |    no    |
| index_document                        | The name of the index document. CloudFront serves it for the root of the site, and, when pretty_urls is set, for every path that ends in a slash.                                                                                                                                                                                                                                                                         | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"index.html"`                           |    no    |
| log_bucket_name                       | The name of the S3 bucket for storing access logs. Required when create_log_bucket is false and enable_logging is true.                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                                     |    no    |
| log_bucket_object_lock_days           | Default retention period, in days, for object lock on the logging bucket.                                                                                                                                                                                                                                                                                                                                                 | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `365`                                    |    no    |
| log_bucket_object_lock_enabled        | Whether to enable S3 Object Lock on the logging bucket. This only applies at bucket creation time. S3 server access logs can't be delivered to a bucket with Object Lock, so only CloudFront logs are written when this is true.                                                                                                                                                                                          | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `true`                                   |    no    |
| log_bucket_object_lock_mode           | Default object lock retention mode for the logging bucket. Valid values are GOVERNANCE or COMPLIANCE.                                                                                                                                                                                                                                                                                                                     | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"GOVERNANCE"`                           |    no    |
| log_bucket_target_prefix              | The prefix for log objects in the logging bucket.                                                                                                                                                                                                                                                                                                                                                                         | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                                     |    no    |
| noncurrent_version_expiration_days    | The number of days to keep noncurrent versions of website objects, which every deploy that changes or deletes an object creates. Set to null to keep them indefinitely and leave the bucket's lifecycle configuration unmanaged.                                                                                                                                                                                          | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `30`                                     |    no    |
| pretty_urls                           | Serves pages without .html in their URLs, using a CloudFront Function. Set to "directory" when pages are built as about/index.html, so /about/ serves that page and /about redirects to /about/, or to "file" when pages are built as about.html, so /about serves that page. In both styles, a path ending in a slash serves the index document in that directory. Leave null to serve objects only by their exact keys. | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `null`                                   |    no    |
| route53_zone_id                       | The ID of the Route 53 hosted zone for domain_name. When set, the module validates the certificate with a DNS record in the zone and waits for it to be issued before creating the distribution, and creates A and AAAA alias records for the distribution.                                                                                                                                                               | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `null`                                   |    no    |
| tags                                  | The tags to apply to all taggable resources.                                                                                                                                                                                                                                                                                                                                                                              | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                              | `{}`                                     |    no    |

### Outputs

| Name                                  | Description                                           |
| ------------------------------------- | ----------------------------------------------------- |
| bucket_arn                            | The ARN of the S3 bucket.                             |
| bucket_id                             | The ID of the S3 bucket.                              |
| bucket_name                           | The name of the S3 bucket.                            |
| certificate_arn                       | The ARN of the ACM certificate.                       |
| certificate_domain_validation_options | The domain validation options of the ACM certificate. |
| cloudfront_distribution_arn           | The ARN of the CloudFront distribution.               |
| cloudfront_distribution_id            | The CloudFront distribution ID.                       |
| cloudfront_domain_name                | The CloudFront domain name.                           |
| cloudfront_hosted_zone_id             | The hosted zone ID of the CloudFront distribution.    |

<!-- END_TF_DOCS -->

## License

© 2023 [Daniel Morris]\
Made available under the terms of the [MIT License].

[aws]: https://aws.amazon.com
[aws provider]: https://registry.terraform.io/providers/hashicorp/aws
[cloudfront]: https://aws.amazon.com/cloudfront
[daniel morris]: https://unfun.co
[mit license]: LICENSE.md
[origin access control]: https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-cloudfront-introduces-origin-access-control-oac/
[s3]: https://aws.amazon.com/s3
[terraform]: https://terraform.io
