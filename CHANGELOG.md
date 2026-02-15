# Changelog

## [0.5.0](https://github.com/unfunco/terraform-aws-static-website/compare/v0.4.0...v0.5.0) (2026-02-15)


### 💡 New features

* Add support for custom origins and behaviour ([#29](https://github.com/unfunco/terraform-aws-static-website/issues/29)) ([d9bf8cd](https://github.com/unfunco/terraform-aws-static-website/commit/d9bf8cd85d7544626f214589f3536a8abfa24c08))
* Lock objects in the logs bucket by default ([#35](https://github.com/unfunco/terraform-aws-static-website/issues/35)) ([bb86a1e](https://github.com/unfunco/terraform-aws-static-website/commit/bb86a1e58dc692414b61b65e6ec13a34c9416502))


### 🐛 Bug fixes

* Never use the default CloudFront certificate ([#33](https://github.com/unfunco/terraform-aws-static-website/issues/33)) ([6d31edf](https://github.com/unfunco/terraform-aws-static-website/commit/6d31edfffe201d25ba1a149ce27a55bcf1939c5e))
* Update CI policy to include the log bucket ([#34](https://github.com/unfunco/terraform-aws-static-website/issues/34)) ([56b7758](https://github.com/unfunco/terraform-aws-static-website/commit/56b7758c75f3268c7e074c8ab00c54bffb5f0fb4))


### 🧹 Miscellaneous

* Document the CI policy module ([#31](https://github.com/unfunco/terraform-aws-static-website/issues/31)) ([340e5b3](https://github.com/unfunco/terraform-aws-static-website/commit/340e5b34d705c46478b26c7e634eae9a4d3e038b))

## [0.4.0](https://github.com/unfunco/terraform-aws-static-website/compare/v0.3.0...v0.4.0) (2026-02-08)


### 💡 New features

* Add an IAM policy for CI pipelines ([#27](https://github.com/unfunco/terraform-aws-static-website/issues/27)) ([f24c092](https://github.com/unfunco/terraform-aws-static-website/commit/f24c09263da1c889d2f662db64e2d8c16d2bfaf6))

## [0.3.0](https://github.com/unfunco/terraform-aws-static-website/compare/v0.2.0...v0.3.0) (2026-01-25)


### 💡 New features

* Add a force_destroy variable for S3 buckets ([#22](https://github.com/unfunco/terraform-aws-static-website/issues/22)) ([c5e48f8](https://github.com/unfunco/terraform-aws-static-website/commit/c5e48f8504b4ae53ba96dc5c23d880b428e18b5a))
* Add default index and error documents ([#15](https://github.com/unfunco/terraform-aws-static-website/issues/15)) ([0c641b6](https://github.com/unfunco/terraform-aws-static-website/commit/0c641b640a505b445b4aa51e83789973c37dd709))
* Allow custom log bucket target prefixes ([#19](https://github.com/unfunco/terraform-aws-static-website/issues/19)) ([dbec703](https://github.com/unfunco/terraform-aws-static-website/commit/dbec703df6aa2e7ce256360ab6d5b0d0e6fe86bf))
* Allow the ACM certificate ARN to be set ([#20](https://github.com/unfunco/terraform-aws-static-website/issues/20)) ([d6416d0](https://github.com/unfunco/terraform-aws-static-website/commit/d6416d0f93c1a0560dbc89c0cfc7e25ed2892dc1))
* Make more of CloudFront configurable ([#23](https://github.com/unfunco/terraform-aws-static-website/issues/23)) ([b492527](https://github.com/unfunco/terraform-aws-static-website/commit/b49252795eeddc8cbab580cc8f42c1485f7938b3))


### 🐛 Bug fixes

* Allow custom CloudFront distribution ARNs ([#18](https://github.com/unfunco/terraform-aws-static-website/issues/18)) ([8373f78](https://github.com/unfunco/terraform-aws-static-website/commit/8373f7815afbeb8a252195dd6a3f451b35affffd))
* Update references to non-existent S3 bucket ([#21](https://github.com/unfunco/terraform-aws-static-website/issues/21)) ([c971b3f](https://github.com/unfunco/terraform-aws-static-website/commit/c971b3f4a63d130a4d9c99310eb3016edd04a694))
* Update version numbers in the README ([#25](https://github.com/unfunco/terraform-aws-static-website/issues/25)) ([39b428e](https://github.com/unfunco/terraform-aws-static-website/commit/39b428eb872f05ba816ed4d867aa47537ab6b6b9))


### 🧹 Miscellaneous

* Add README badges ([#26](https://github.com/unfunco/terraform-aws-static-website/issues/26)) ([3a4bf49](https://github.com/unfunco/terraform-aws-static-website/commit/3a4bf49c4309f12d4711cd194b3a4c190d9ebed5))
* Configure regex to update version in README ([#24](https://github.com/unfunco/terraform-aws-static-website/issues/24)) ([851b58d](https://github.com/unfunco/terraform-aws-static-website/commit/851b58dc0a7e5c78e89daf49e6476cf1edfb0606))

## [0.2.0](https://github.com/unfunco/terraform-aws-static-website/compare/v0.1.0...v0.2.0) (2026-01-16)


### 💡 New features

* Add a dependabot configuration ([#6](https://github.com/unfunco/terraform-aws-static-website/issues/6)) ([44c4805](https://github.com/unfunco/terraform-aws-static-website/commit/44c4805bfebf6a0901145ccafbed00a9b9085281))
* Add create variable and configure resources ([#9](https://github.com/unfunco/terraform-aws-static-website/issues/9)) ([b768f9a](https://github.com/unfunco/terraform-aws-static-website/commit/b768f9ab696f068675e1446c42d90b52b1fd07b2))
* Improve best practices and security ([#10](https://github.com/unfunco/terraform-aws-static-website/issues/10)) ([cc4b7f1](https://github.com/unfunco/terraform-aws-static-website/commit/cc4b7f1f831728b42ea2732d06564668dfae59ad))


### 🐛 Bug fixes

* Set the automated release version to v0.2.0 ([#4](https://github.com/unfunco/terraform-aws-static-website/issues/4)) ([d7fab11](https://github.com/unfunco/terraform-aws-static-website/commit/d7fab115743bd2763a2d0e1729433e03dab70433))
* Set the log bucket default to an empty string ([#13](https://github.com/unfunco/terraform-aws-static-website/issues/13)) ([364f51e](https://github.com/unfunco/terraform-aws-static-website/commit/364f51e3e7dc5e463fc66b77212d4a41dd35bbac))
* Use BucketOwnerPreferred instead of Enforced ([#14](https://github.com/unfunco/terraform-aws-static-website/issues/14)) ([e916c30](https://github.com/unfunco/terraform-aws-static-website/commit/e916c30e73591c498bdc27b49313bbbd1656c098))


### 🧹 Miscellaneous

* Add a terraform-docs configuration ([#12](https://github.com/unfunco/terraform-aws-static-website/issues/12)) ([df9ebf6](https://github.com/unfunco/terraform-aws-static-website/commit/df9ebf6126a6c42db00dad3ddf5161e6baf97e25))
* Automate releases with release-please ([#2](https://github.com/unfunco/terraform-aws-static-website/issues/2)) ([82fc1e7](https://github.com/unfunco/terraform-aws-static-website/commit/82fc1e725e260227c5649864acce497b77886a12))
* Bump hashicorp/setup-terraform from 2 to 3 ([#7](https://github.com/unfunco/terraform-aws-static-website/issues/7)) ([9cef1db](https://github.com/unfunco/terraform-aws-static-website/commit/9cef1db3126bd304d64e993a01f0659cba0caed9))
* Improve the description in the README ([#11](https://github.com/unfunco/terraform-aws-static-website/issues/11)) ([ada742c](https://github.com/unfunco/terraform-aws-static-website/commit/ada742c2428447a06973dde077b49aa59b6fd26d))
* Upgrade providers and apply the MIT License ([#1](https://github.com/unfunco/terraform-aws-static-website/issues/1)) ([0c267cf](https://github.com/unfunco/terraform-aws-static-website/commit/0c267cf03597d601b51af391a634a86e6714196e))
