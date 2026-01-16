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
