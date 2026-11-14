// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

// These tests only plan, with static credentials that never reach AWS, so
// they run without an AWS account. The policy documents are built locally
// by the provider, so their JSON is known at plan time.

provider "aws" {
  access_key                  = "test"
  region                      = "eu-west-1"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

variables {
  bucket_name = "example.com"
}

run "content_permissions" {
  command = plan

  variables {
    cloudfront_distribution_arn = "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
  }

  assert {
    condition = [for statement in jsondecode(output.policy_document).Statement : statement.Sid] == [
      "StaticWebsiteContentPermissionsS3Bucket",
      "StaticWebsiteContentPermissionsS3Object",
      "StaticWebsiteContentPermissionsCloudFront",
    ]
    error_message = "Only content permissions are granted by default."
  }

  assert {
    condition = one([
      for statement in jsondecode(output.policy_document).Statement :
      statement.Resource if statement.Sid == "StaticWebsiteContentPermissionsCloudFront"
    ]) == "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
    error_message = "Invalidation is limited to the distribution."
  }
}

run "required_resource_tags" {
  command = plan

  variables {
    required_resource_tags = {
      environment = "live"
    }
  }

  assert {
    condition = one([
      for statement in jsondecode(output.policy_document).Statement :
      statement.Condition.StringEquals["aws:ResourceTag/environment"] if statement.Sid == "StaticWebsiteContentPermissionsCloudFront"
    ]) == "live"
    error_message = "Invalidation requires the distribution to have the tag."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(output.policy_document).Statement :
      lookup(statement, "Condition", null) == null if startswith(statement.Sid, "StaticWebsiteContentPermissionsS3")
    ])
    error_message = "S3 permissions have no tag conditions, because S3 ignores resource tags on buckets without ABAC."
  }
}

run "infrastructure_permissions" {
  command = plan

  variables {
    attach_infrastructure_permissions = true
  }

  assert {
    condition = alltrue([
      for action in ["s3:GetBucketAcl", "s3:PutBucketAcl", "s3:GetBucketCORS", "s3:GetEncryptionConfiguration"] :
      contains(one([
        for statement in jsondecode(output.policy_document).Statement :
        statement.Action if statement.Sid == "StaticWebsiteInfrastructurePermissionsS3"
      ]), action)
    ])
    error_message = "The provider can read and manage the buckets' ACLs and configuration."
  }

  assert {
    condition = contains([
      for statement in jsondecode(output.policy_document).Statement : statement.Sid
    ], "StaticWebsiteInfrastructurePermissionsCloudFrontFunction")
    error_message = "CloudFront Functions can be managed."
  }

  assert {
    condition = !anytrue([
      for statement in jsondecode(output.policy_document).Statement : startswith(statement.Sid, "StaticWebsiteInfrastructurePermissionsRoute53")
    ])
    error_message = "No Route 53 permissions are granted without a hosted zone."
  }
}

run "infrastructure_permissions_with_route53" {
  command = plan

  variables {
    attach_infrastructure_permissions = true
    route53_zone_id                   = "Z0123456789ABCDEFGHIJ"
  }

  assert {
    condition = one([
      for statement in jsondecode(output.policy_document).Statement :
      statement.Resource if statement.Sid == "StaticWebsiteInfrastructurePermissionsRoute53"
    ]) == "arn:aws:route53:::hostedzone/Z0123456789ABCDEFGHIJ"
    error_message = "Record changes are limited to the hosted zone."
  }
}
