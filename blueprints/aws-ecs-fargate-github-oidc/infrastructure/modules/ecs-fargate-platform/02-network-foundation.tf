#==============================================================================
# VPC
#==============================================================================

module "vpc" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/vpc?ref=v0.1.0"

  name            = local.name_prefix
  cidr_block      = var.vpc_cidr_block
  enable_flow_log = false
  tags            = local.tags
}

#==============================================================================
# SUBNETS
#==============================================================================

module "subnets" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/subnet?ref=v0.1.0"

  name                              = local.name_prefix
  vpc_id                            = module.vpc.vpc_id
  igw_id                            = module.vpc.igw_id
  public_subnets                    = var.public_subnet_cidr_blocks
  public_subnet_availability_zones  = local.availability_zones
  private_subnets                   = var.private_subnet_cidr_blocks
  private_subnet_availability_zones = local.availability_zones
  enable_nat_gateway                = var.enable_nat_gateway
  single_nat_gateway                = var.enable_nat_gateway
  map_public_ip_on_launch           = false
  tags                              = local.tags
}

#==============================================================================
# LOAD BALANCER SECURITY GROUP
#==============================================================================

module "alb_security_group" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/security-group?ref=v0.1.0"

  name        = local.alb_security_group
  description = "Security group for the public ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.allowed_http_cidr_blocks
      description = "HTTP access to the public ALB"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Outbound access from ALB"
    }
  ]

  tags = local.tags
}

#==============================================================================
# SERVICE SECURITY GROUP
#==============================================================================

module "service_security_group" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/security-group?ref=v0.1.0"

  name        = local.service_security_group
  description = "Security group for private ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "Application traffic from ALB"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Outbound access from ECS tasks"
    }
  ]

  tags = local.tags
}

#==============================================================================
# VPC ENDPOINT SECURITY GROUP
#==============================================================================

module "vpc_endpoint_security_group" {
  count = var.enable_vpc_endpoints ? 1 : 0

  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/security-group?ref=v0.1.0"

  name        = local.endpoint_security_group
  description = "Security group for private AWS service endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.service_security_group.security_group_id
      description              = "HTTPS from private ECS tasks"
    }
  ]

  tags = local.tags
}

#==============================================================================
# INTERFACE VPC ENDPOINTS
#==============================================================================

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? local.interface_endpoint_services : toset([])

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.subnets.private_subnet_ids
  security_group_ids  = [module.vpc_endpoint_security_group[0].security_group_id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-${replace(each.value, ".", "-")}-endpoint"
    }
  )
}

#==============================================================================
# S3 GATEWAY VPC ENDPOINT
#==============================================================================

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.subnets.private_route_table_ids

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-s3-endpoint"
    }
  )
}
