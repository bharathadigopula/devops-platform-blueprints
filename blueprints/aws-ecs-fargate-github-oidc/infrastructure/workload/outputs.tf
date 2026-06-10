#==============================================================================
# APPLICATION OUTPUTS
#==============================================================================

output "application_url" {
  description = "HTTP URL for the public Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for application images"
  value       = module.ecr.repository_url
}

#==============================================================================
# ECS OUTPUTS
#==============================================================================

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_service.service_name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

#==============================================================================
# NETWORK OUTPUTS
#==============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS tasks"
  value       = module.subnets.private_subnet_ids
}

#==============================================================================
# OBSERVABILITY OUTPUTS
#==============================================================================

output "log_group_name" {
  description = "CloudWatch log group name for the application"
  value       = local.log_group_name
}

