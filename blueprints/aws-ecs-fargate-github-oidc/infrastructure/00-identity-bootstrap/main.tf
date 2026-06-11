#==============================================================================
# ACCOUNT DATA
#==============================================================================

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

#==============================================================================
# LOCAL VALUES
#==============================================================================

locals {
  account_id              = data.aws_caller_identity.current.account_id
  partition               = data.aws_partition.current.partition
  role_name               = coalesce(var.role_name, "${var.project_name}-${var.environment}-github-actions")
  trusted_subject         = "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
  state_bucket_arn        = "arn:${local.partition}:s3:::${var.project_name}-*-tfstate-${local.account_id}-*"
  state_bucket_object_arn = "${local.state_bucket_arn}/*"

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
# BLUEPRINT PERMISSIONS POLICY
#==============================================================================

data "aws_iam_policy_document" "blueprint_permissions" {
  statement {
    sid = "ReadAccountContext"

    actions = [
      "iam:GetAccountSummary",
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.enable_state_backend_permissions ? [1] : []

    content {
      sid = "ManageTerraformStateStorage"

      actions = [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucketTagging",
        "s3:DeleteObject",
        "s3:GetBucketAcl",
        "s3:GetBucketTagging",
        "s3:GetBucketLocation",
        "s3:GetBucketOwnershipControls",
        "s3:GetBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketVersioning",
        "s3:GetEncryptionConfiguration",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutBucketOwnershipControls",
        "s3:PutBucketPolicy",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging",
        "s3:PutBucketVersioning",
        "s3:PutEncryptionConfiguration",
        "s3:PutObject"
      ]

      resources = [
        local.state_bucket_arn,
        local.state_bucket_object_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_state_backend_permissions ? [1] : []

    content {
      sid = "ManageTerraformStateLocks"

      actions = [
        "dynamodb:CreateTable",
        "dynamodb:DeleteItem",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:ListTagsOfResource",
        "dynamodb:PutItem",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:UpdateContinuousBackups",
        "dynamodb:UpdateTable"
      ]

      resources = [
        "arn:${local.partition}:dynamodb:${var.aws_region}:${local.account_id}:table/${var.project_name}-*-terraform-locks"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_state_backend_permissions || var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageBlueprintKmsKeys"

      actions = [
        "kms:CancelKeyDeletion",
        "kms:CreateAlias",
        "kms:CreateGrant",
        "kms:CreateKey",
        "kms:Decrypt",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListAliases",
        "kms:ListGrants",
        "kms:ListResourceTags",
        "kms:PutKeyPolicy",
        "kms:RevokeGrant",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:UpdateAlias"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageNetworking"

      actions = [
        "ec2:AllocateAddress",
        "ec2:AssociateRouteTable",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSubnet",
        "ec2:CreateTags",
        "ec2:CreateVpc",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNatGateway",
        "ec2:DeleteRoute",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteTags",
        "ec2:DeleteVpc",
        "ec2:DeleteVpcEndpoints",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNatGateways",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeVpcs",
        "ec2:DetachInternetGateway",
        "ec2:DisassociateRouteTable",
        "ec2:ModifySubnetAttribute",
        "ec2:ModifyVpcAttribute",
        "ec2:ModifyVpcEndpoint",
        "ec2:ReleaseAddress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageLoadBalancing"

      actions = [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RemoveTags"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageContainerPlatform"

      actions = [
        "ecs:CreateCluster",
        "ecs:CreateService",
        "ecs:DeleteCluster",
        "ecs:DeleteService",
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:ListServices",
        "ecs:ListTagsForResource",
        "ecs:RegisterTaskDefinition",
        "ecs:TagResource",
        "ecs:UntagResource",
        "ecs:UpdateCluster",
        "ecs:UpdateClusterSettings",
        "ecs:UpdateService"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageContainerRegistry"

      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository",
        "ecr:DeleteLifecyclePolicy",
        "ecr:DeleteRepository",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetRepositoryPolicy",
        "ecr:InitiateLayerUpload",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
        "ecr:PutImage",
        "ecr:PutImageScanningConfiguration",
        "ecr:PutImageTagMutability",
        "ecr:PutLifecyclePolicy",
        "ecr:SetRepositoryPolicy",
        "ecr:TagResource",
        "ecr:UntagResource",
        "ecr:UploadLayerPart"
      ]

      resources = [
        "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ReadContainerRegistryAuth"

      actions = [
        "ecr:GetAuthorizationToken"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageTaskRoles"

      actions = [
        "iam:AttachRolePolicy",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:ListRolePolicies",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateAssumeRolePolicy"
      ]

      resources = [
        "arn:${local.partition}:iam::${local.account_id}:role/${var.project_name}-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "CreateServiceLinkedRoles"

      actions = [
        "iam:CreateServiceLinkedRole"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_workload_permissions ? [1] : []

    content {
      sid = "ManageApplicationLogs"

      actions = [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:ListTagsForResource",
        "logs:PutRetentionPolicy",
        "logs:TagResource",
        "logs:UntagResource"
      ]

      resources = [
        "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/ecs/${var.project_name}-*",
        "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/ecs/${var.project_name}-*:*"
      ]
    }
  }
}

resource "aws_iam_policy" "blueprint_permissions" {
  count = var.create_blueprint_permissions_policy ? 1 : 0

  name        = "${local.role_name}-blueprint-permissions"
  description = "Scoped permissions for ${var.project_name} blueprint workflows"
  policy      = data.aws_iam_policy_document.blueprint_permissions.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "blueprint_permissions" {
  count = var.create_blueprint_permissions_policy ? 1 : 0

  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.blueprint_permissions[0].arn
}

#==============================================================================
# MANAGED POLICY ATTACHMENTS
#==============================================================================

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
