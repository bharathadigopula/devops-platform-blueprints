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

  alb_name               = "${local.name_prefix}-alb"
  alb_security_group     = "${local.name_prefix}-alb-sg"
  cluster_name           = "${local.name_prefix}-cluster"
  container_name         = "app"
  ecr_name               = "${local.name_prefix}/app"
  execution_role_name    = "${local.name_prefix}-execution"
  log_group_name         = "/aws/ecs/${local.name_prefix}"
  service_name           = "${local.name_prefix}-service"
  service_security_group = "${local.name_prefix}-service-sg"
  target_group_name      = "${local.name_prefix}-tg"
  task_role_name         = "${local.name_prefix}-task"
  ecr_kms_key_arn        = coalesce(var.ecr_kms_key_arn, try(aws_kms_key.ecr[0].arn, null))
  ecr_encryption_type    = local.ecr_kms_key_arn != null ? "KMS" : "AES256"

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
# NETWORK
#==============================================================================

module "vpc" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/vpc?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  name            = local.name_prefix
  cidr_block      = var.vpc_cidr_block
  enable_flow_log = false
  tags            = local.tags
}

module "subnets" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/subnet?ref=62c1cedd48e63734528c67720bb157df22f6c738"

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
# SECURITY GROUPS
#==============================================================================

module "alb_security_group" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/security-group?ref=62c1cedd48e63734528c67720bb157df22f6c738"

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

module "service_security_group" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/security-group?ref=62c1cedd48e63734528c67720bb157df22f6c738"

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
# CONTAINER REGISTRY
#==============================================================================

module "ecr" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecr?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  name                 = local.ecr_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  encryption_type      = local.ecr_encryption_type
  kms_key              = local.ecr_kms_key_arn
  force_delete         = var.force_delete_ecr
  tags                 = local.tags
}

#==============================================================================
# LOGS
#==============================================================================

module "logs" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/management/cloudwatch-logs?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  log_groups = [
    {
      name              = local.log_group_name
      retention_in_days = var.log_retention_days
      log_group_class   = "STANDARD"
      tags              = local.tags
    }
  ]

  tags = local.tags
}

#==============================================================================
# IAM
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

module "iam" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/security/iam?ref=62c1cedd48e63734528c67720bb157df22f6c738"

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

#==============================================================================
# ECS TASK DEFINITION
#==============================================================================

resource "aws_ecs_task_definition" "app" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = module.iam.role_arns[local.execution_role_name]
  task_role_arn            = module.iam.role_arns[local.task_role_name]

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${module.ecr.repository_url}:${var.container_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SERVICE_NAME"
          value = local.name_prefix
        },
        {
          name  = "APP_VERSION"
          value = var.container_image_tag
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q -O - http://127.0.0.1:${var.container_port}/health || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 30
        timeout     = 5
      }

      linuxParameters = {
        initProcessEnabled = true
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = local.container_name
        }
      }

      readonlyRootFilesystem = true
    }
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = local.tags

  depends_on = [
    module.iam,
    module.logs
  ]
}

#==============================================================================
# LOAD BALANCER
#==============================================================================

module "alb" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/alb?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  name                       = local.alb_name
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.subnets.public_subnet_ids
  security_groups            = [module.alb_security_group.security_group_id]
  internal                   = false
  enable_deletion_protection = var.alb_deletion_protection

  target_groups = [
    {
      name                 = local.target_group_name
      port                 = var.container_port
      protocol             = "HTTP"
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = 0
      }
    }
  ]

  tags = local.tags
}

#==============================================================================
# ECS CLUSTER AND SERVICE
#==============================================================================

module "ecs_cluster" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecs-cluster?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  name               = local.cluster_name
  container_insights = "enabled"
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]

  tags = local.tags
}

module "ecs_service" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecs-service?ref=62c1cedd48e63734528c67720bb157df22f6c738"

  name                              = local.service_name
  cluster_arn                       = module.ecs_cluster.cluster_arn
  task_definition_arn               = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60
  enable_execute_command            = var.enable_execute_command
  propagate_tags                    = "SERVICE"
  enable_ecs_managed_tags           = true

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  network_configuration = {
    subnets          = module.subnets.private_subnet_ids
    security_groups  = [module.service_security_group.security_group_id]
    assign_public_ip = false
  }

  load_balancer = [
    {
      target_group_arn = module.alb.target_group_arns[0]
      container_name   = local.container_name
      container_port   = var.container_port
    }
  ]

  tags = local.tags

  depends_on = [
    module.alb
  ]
}
