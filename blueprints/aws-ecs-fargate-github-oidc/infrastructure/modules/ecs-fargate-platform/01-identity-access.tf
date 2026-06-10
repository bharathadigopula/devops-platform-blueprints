#==============================================================================
# KMS
#==============================================================================

resource "aws_kms_key" "ecr" {
  count = var.create_ecr_kms_key && var.ecr_kms_key_arn == null ? 1 : 0

  description             = "ECR encryption key for ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.tags
}

resource "aws_kms_alias" "ecr" {
  count = var.create_ecr_kms_key && var.ecr_kms_key_arn == null ? 1 : 0

  name          = "alias/${local.name_prefix}-ecr"
  target_key_id = aws_kms_key.ecr[0].key_id
}

#==============================================================================
# ECS TASK TRUST POLICY
#==============================================================================

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

#==============================================================================
# ECS TASK ROLES
#==============================================================================

module "iam" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/security/iam?ref=v0.1.0"

  roles = [
    {
      name               = local.execution_role_name
      assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
      description        = "ECS task execution role for ${local.name_prefix}"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
      inline_policies = {}
      tags            = local.tags
    },
    {
      name                = local.task_role_name
      assume_role_policy  = data.aws_iam_policy_document.ecs_task_assume_role.json
      description         = "ECS application task role for ${local.name_prefix}"
      managed_policy_arns = []
      inline_policies     = {}
      tags                = local.tags
    }
  ]

  tags = local.tags
}
