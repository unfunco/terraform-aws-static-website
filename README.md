# terraform-aws-static-website

Terraform module for creating a static website on AWS.

## 🔨 Getting started

### Requirements

- [Terraform] 1.3+

### Installation and usage

```terraform
provider "aws" {
  region = var.region
}

module "website" {
  source  = "registry.terraform.io/unfunco/static-website/aws"
  version = "0.1.0"

  domain_name = "unfun.co"
}
```

## License

© 2023 [Daniel Morris]\
Made available under the terms of the [Apache License 2.0].

[apache license 2.0]: LICENSE.md
[daniel morris]: https://unfun.co
[terraform]: https://terraform.io
