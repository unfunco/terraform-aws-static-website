# terraform-aws-static-website

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
  version = "0.2.0"

  domain_name = "unfun.co"
}
```
<!-- x-release-please-end -->

<!-- BEGIN_TF_DOCS -->

### Resources

| Name                                                                                                                                                        | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                                     | resource    |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)                     | resource    |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control)   | resource    |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                 | resource    |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                 | resource    |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource    |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging)                                 | resource    |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls)           | resource    |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls)           | resource    |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                                   | resource    |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)         | resource    |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)         | resource    |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                           | resource    |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                           | resource    |
| [aws_s3_object.error_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                       | resource    |
| [aws_s3_object.index_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                       | resource    |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                          | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                                              | data source |

### Inputs

| Name                                  | Description                                                                                                               | Type           | Default             | Required |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------- | :------: |
| acm_certificate_arn                   | The ARN of an existing ACM certificate to use for the CloudFront distribution. Required when create_certificate is false. | `string`       | `""`                |    no    |
| bucket_name                           | The name of the S3 bucket for storing website content.                                                                    | `string`       | `""`                |    no    |
| cloudfront_allowed_methods            | The HTTP methods allowed by the CloudFront distribution.                                                                  | `list(string)` | `[ "GET", "HEAD" ]` |    no    |
| cloudfront_distribution_arn           | The ARN of an existing CloudFront distribution to use for the S3 bucket policy.                                           | `string`       | `""`                |    no    |
| cloudfront_distribution_price_class   | The price class for the CloudFront distribution.                                                                          | `string`       | `"PriceClass_All"`  |    no    |
| cloudfront_response_headers_policy_id | The ID of a response headers policy to attach to the CloudFront distribution.                                             | `string`       | `null`              |    no    |
| cloudfront_retain_on_delete           | Whether to retain the CloudFront distribution when deleting the resource.                                                 | `bool`         | `false`             |    no    |
| cloudfront_web_acl_id                 | The ID of a WAF web ACL to associate with the CloudFront distribution.                                                    | `string`       | `null`              |    no    |
| create                                | Whether to create resources.                                                                                              | `bool`         | `true`              |    no    |
| create_certificate                    | Whether to create an ACM certificate.                                                                                     | `bool`         | `true`              |    no    |
| create_cloudfront_distribution        | Whether to create a CloudFront distribution.                                                                              | `bool`         | `true`              |    no    |
| create_default_documents              | Whether to create default index and error documents.                                                                      | `bool`         | `true`              |    no    |
| create_log_bucket                     | Whether to create a dedicated logging bucket.                                                                             | `bool`         | `true`              |    no    |
| domain_name                           | The domain name for the website.                                                                                          | `string`       | n/a                 |   yes    |
| enable_logging                        | Whether to enable access logging for S3 and CloudFront.                                                                   | `bool`         | `true`              |    no    |
| enable_versioning                     | Whether to enable versioning on the S3 bucket.                                                                            | `bool`         | `true`              |    no    |
| error_document                        | The path to the error document returned for 4xx errors.                                                                   | `string`       | `"error.html"`      |    no    |
| force_destroy                         | Whether to allow bucket deletion even when not empty.                                                                     | `bool`         | `false`             |    no    |
| index_document                        | The path to the index document returned for directory requests.                                                           | `string`       | `"index.html"`      |    no    |
| log_bucket_name                       | The name of the S3 bucket for storing access logs.                                                                        | `string`       | `""`                |    no    |
| log_bucket_target_prefix              | The prefix for log objects in the logging bucket.                                                                         | `string`       | `""`                |    no    |
| tags                                  | The tags to apply to all taggable resources.                                                                              | `map(string)`  | `{}`                |    no    |

### Outputs

| Name                                  | Description                                           |
| ------------------------------------- | ----------------------------------------------------- |
| bucket_arn                            | The ARN of the S3 bucket.                             |
| bucket_id                             | The ID of the S3 bucket.                              |
| certificate_arn                       | The ARN of the ACM certificate.                       |
| certificate_domain_validation_options | The domain validation options of the ACM certificate. |
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
