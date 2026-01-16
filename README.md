# terraform-aws-static-website

Terraform module for creating a static website on [AWS] using [S3] and
[CloudFront].

## Getting started

### Requirements

- [Terraform] 1.14+

### Installation and usage

```terraform
module "website" {
  source  = "unfunco/static-website/aws"
  version = "0.1.0"

  domain_name = "unfun.co"
}
```

## License

© 2023 [Daniel Morris]\
Made available under the terms of the [MIT License].

[aws]: https://aws.amazon.com
[cloudfront]: https://aws.amazon.com/cloudfront
[daniel morris]: https://unfun.co
[mit license]: LICENSE.md
[s3]: https://aws.amazon.com/s3
[terraform]: https://terraform.io
