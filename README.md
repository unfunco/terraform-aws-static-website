# terraform-aws-static-website

Terraform module for [AWS] static website hosting with [S3], [CloudFront] CDN,
automatic SSL/TLS certificates, HTTP/3, IPv6, and secure defaults using
[Origin Access Control] (OAC).

## Getting started

### Requirements

- [Terraform] 1.14+ and the [AWS provider] 6.0+

### Installation and usage

```terraform
module "website" {
  source  = "unfunco/static-website/aws"
  version = "0.1.0"

  domain_name = "unfun.co"
}
```

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
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                          | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                                              | data source |

### Inputs

| Name                           | Description                                               | Type          | Default        | Required |
| ------------------------------ | --------------------------------------------------------- | ------------- | -------------- | :------: |
| bucket_name                    | Name of the S3 bucket that will store the website.        | `string`      | `""`           |    no    |
| bucket_name_logs               | Name of the S3 bucket that will store logs.               | `string`      | `null`         |    no    |
| create                         | Enable/disable the creation of all resources.             | `bool`        | `true`         |    no    |
| create_certificate             | Enable/disable the creation of an ACM certificate.        | `bool`        | `true`         |    no    |
| create_cloudfront_distribution | Enable/disable the creation of a CloudFront distribution. | `bool`        | `true`         |    no    |
| create_log_bucket              | Enable/disable the creation of a log bucket.              | `bool`        | `true`         |    no    |
| domain_name                    | Domain name of the website.                               | `string`      | n/a            |   yes    |
| enable_logging                 | Enable/disable logging on the S3 bucket.                  | `bool`        | `true`         |    no    |
| enable_versioning              | Enable/disable versioning on the S3 bucket.               | `bool`        | `true`         |    no    |
| error_document                 | Document returned when a 4xx error occurs.                | `string`      | `"error.html"` |    no    |
| index_document                 | Document returned for directory requests.                 | `string`      | `"index.html"` |    no    |
| tags                           | Tags to apply to all applicable resources.                | `map(string)` | `{}`           |    no    |

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
