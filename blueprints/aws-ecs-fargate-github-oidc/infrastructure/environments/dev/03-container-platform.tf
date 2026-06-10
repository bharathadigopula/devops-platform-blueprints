#==============================================================================
# CONTAINER REGISTRY
#==============================================================================

module "ecr" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecr?ref=v0.1.0"

  name                 = local.ecr_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  encryption_type      = local.ecr_encryption_type
  kms_key              = local.ecr_kms_key_arn
  force_delete         = var.force_delete_ecr
  tags                 = local.tags
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
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/networking/alb?ref=v0.1.0"

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
# ECS CLUSTER
#==============================================================================

module "ecs_cluster" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecs-cluster?ref=v0.1.0"

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

#==============================================================================
# ECS SERVICE
#==============================================================================

module "ecs_service" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/containers/ecs-service?ref=v0.1.0"

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
