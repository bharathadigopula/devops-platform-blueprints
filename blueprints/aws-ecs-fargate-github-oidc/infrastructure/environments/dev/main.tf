#==============================================================================
# ECS FARGATE PLATFORM
#==============================================================================

module "platform" {
  source = "../../modules/ecs-fargate-platform"

  aws_region                 = var.aws_region
  project_name               = var.project_name
  environment                = var.environment
  name_prefix                = var.name_prefix
  vpc_cidr_block             = "10.42.0.0/16"
  public_subnet_cidr_blocks  = ["10.42.0.0/24", "10.42.1.0/24"]
  private_subnet_cidr_blocks = ["10.42.10.0/24", "10.42.11.0/24"]
  enable_nat_gateway         = var.enable_nat_gateway
  enable_vpc_endpoints       = var.enable_vpc_endpoints
  allowed_http_cidr_blocks   = var.allowed_http_cidr_blocks
  container_image_tag        = var.container_image_tag
  desired_count              = var.desired_count
  enable_execute_command     = var.enable_execute_command
  log_retention_days         = var.log_retention_days
  alb_deletion_protection    = var.alb_deletion_protection
  force_delete_ecr           = var.force_delete_ecr
  create_ecr_kms_key         = var.create_ecr_kms_key
  tags                       = var.tags
}
