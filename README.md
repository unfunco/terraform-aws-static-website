# terraform-aws-static-website

## Getting started

### Requirements

- [Terraform] 1.0+

### Installation and usage

```terraform
provider "aws" {
  region = var.region
}

module "static_website" {
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
