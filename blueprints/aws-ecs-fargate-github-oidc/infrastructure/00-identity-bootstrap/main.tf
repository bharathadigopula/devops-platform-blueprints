#==============================================================================
# LOCAL VALUES
#==============================================================================

locals {
  role_name       = coalesce(var.role_name, "${var.project_name}-${var.environment}-github-actions")
  trusted_subject = "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_branch}"

  tags = merge(
    var.tags,
    {
      Blueprint   = "aws-ecs-fargate-github-oidc"
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  )
}

#==============================================================================
# GITHUB OIDC PROVIDER
#==============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = local.tags
}

#==============================================================================
# GITHUB ACTIONS TRUST POLICY
#==============================================================================

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        local.trusted_subject
      ]
    }
  }
}

#==============================================================================
# GITHUB ACTIONS ROLE
#==============================================================================

resource "aws_iam_role" "github_actions" {
  name                 = local.role_name
  assume_role_policy   = data.aws_iam_policy_document.github_actions_trust.json
  description          = "GitHub Actions deployment role for ${var.project_name} ${var.environment}"
  max_session_duration = 3600
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

#==============================================================================
# MANAGED POLICY ATTACHMENTS
#==============================================================================

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
