#==============================================================================
# GITHUB OIDC OUTPUTS
#==============================================================================

output "github_actions_role_arn" {
  description = "IAM role ARN to store as the GitHub repository variable AWS_ROLE_TO_ASSUME"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM role name created for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}

output "github_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for GitHub Actions"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "trusted_subject" {
  description = "GitHub OIDC subject allowed to assume the role"
  value       = local.trusted_subject
}

