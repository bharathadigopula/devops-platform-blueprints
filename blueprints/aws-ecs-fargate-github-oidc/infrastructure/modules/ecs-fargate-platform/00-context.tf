#==============================================================================
# ACCOUNT DATA
#==============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

#==============================================================================
# LOCAL VALUES
#==============================================================================

locals {
  name_prefix = coalesce(var.name_prefix, "${var.project_name}-${var.environment}")

  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  alb_name                    = "${local.name_prefix}-alb"
  alb_security_group          = "${local.name_prefix}-alb-sg"
  cluster_name                = "${local.name_prefix}-cluster"
  container_name              = "app"
  ecr_name                    = "${local.name_prefix}/app"
  endpoint_security_group     = "${local.name_prefix}-endpoint-sg"
  execution_role_name         = "${local.name_prefix}-execution"
  log_group_name              = "/aws/ecs/${local.name_prefix}"
  service_name                = "${local.name_prefix}-service"
  service_security_group      = "${local.name_prefix}-service-sg"
  target_group_name           = "${local.name_prefix}-tg"
  task_role_name              = "${local.name_prefix}-task"
  ecr_kms_key_arn             = coalesce(var.ecr_kms_key_arn, try(aws_kms_key.ecr[0].arn, null))
  ecr_encryption_type         = local.ecr_kms_key_arn != null ? "KMS" : "AES256"
  interface_endpoint_services = toset(["ecr.api", "ecr.dkr", "logs"])

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
