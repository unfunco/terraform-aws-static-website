// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

output "policy_document" {
  description = "The JSON-encoded IAM policy document. Can be passed to iam_role_inline_policies in the unfunco/oidc-github module."
  value       = var.create ? data.aws_iam_policy_document.combined[0].json : ""
}
