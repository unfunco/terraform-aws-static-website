# IAM policy for CI/CD pipelines

### Installation and usage

<!-- x-release-please-start-version -->

```terraform
module "ci_iam_policy" {
  source  = "unfunco/static-website/aws//modules/ci-iam-policy"
  version = "0.5.0"

  attach_content_permissions  = true
  bucket_name                 = "unfun.co"
}
```

<!-- x-release-please-end -->

<!-- BEGIN_TF_DOCS -->

### Resources

| Name                                                                                                                                         | Type        |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)       | data source |
| [aws_iam_policy_document.content](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)        | data source |
| [aws_iam_policy_document.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                               | data source |

### Inputs

| Name                              | Description                                                                                                                                                                                                                                                                                              | Type          | Default | Required |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| attach_content_permissions        | Whether to attach permissions for deploying content to the S3 bucket.                                                                                                                                                                                                                                    | `bool`        | `true`  |    no    |
| attach_infrastructure_permissions | Whether to attach permissions for managing the underlying infrastructure.                                                                                                                                                                                                                                | `bool`        | `false` |    no    |
| bucket_name                       | The name of the S3 bucket for the static website.                                                                                                                                                                                                                                                        | `string`      | n/a     |   yes    |
| cloudfront_distribution_arn       | The ARN of the CloudFront distribution for scoping cache invalidation permissions.                                                                                                                                                                                                                       | `string`      | `"*"`   |    no    |
| create                            | Whether to create resources.                                                                                                                                                                                                                                                                             | `bool`        | `true`  |    no    |
| log_bucket_name                   | The name of the S3 bucket used for access logs. Leave empty to use the bucket name followed by -logs, as the website module does.                                                                                                                                                                        | `string`      | `""`    |    no    |
| required_resource_tags            | Tags the CloudFront distribution must have for the cache invalidation permission, as aws:ResourceTag conditions. Keys are tag names and values are required tag values. The S3 permissions are scoped to the bucket's ARN instead, because S3 only evaluates resource tags on buckets with ABAC enabled. | `map(string)` | `{}`    |    no    |
| route53_zone_id                   | The ID of the Route 53 hosted zone passed to the website module, if any. Infrastructure permissions then include managing records in that zone.                                                                                                                                                          | `string`      | `null`  |    no    |

### Outputs

| Name            | Description                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------ |
| policy_document | The JSON-encoded IAM policy document. Can be passed to iam_role_inline_policies in the unfunco/oidc-github module. |

<!-- END_TF_DOCS -->

## License

© 2026 [Daniel Morris]\
Made available under the terms of the [MIT License].

[aws]: https://aws.amazon.com
[aws provider]: https://registry.terraform.io/providers/hashicorp/aws
[cloudfront]: https://aws.amazon.com/cloudfront
[daniel morris]: https://unfun.co
[mit license]: ../../LICENSE.md
[origin access control]: https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-cloudfront-introduces-origin-access-control-oac/
[s3]: https://aws.amazon.com/s3
[terraform]: https://terraform.io
