#==============================================================================
# APPLICATION OUTPUTS
#==============================================================================

output "application_url" {
  description = "HTTP URL for the public Application Load Balancer"
  value       = module.platform.application_url
}

output "ecr_repository_url" {
  description = "ECR repository URL for application images"
  value       = module.platform.ecr_repository_url
}

#==============================================================================
# ECS OUTPUTS
#==============================================================================

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.platform.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.platform.ecs_service_name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.platform.task_definition_arn
}

#==============================================================================
# NETWORK OUTPUTS
#==============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.platform.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB"
  value       = module.platform.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS tasks"
  value       = module.platform.private_subnet_ids
}

output "interface_vpc_endpoint_ids" {
  description = "Interface VPC endpoint IDs for private AWS service access"
  value       = module.platform.interface_vpc_endpoint_ids
}

output "s3_vpc_endpoint_id" {
  description = "S3 gateway VPC endpoint ID"
  value       = module.platform.s3_vpc_endpoint_id
}

#==============================================================================
# OBSERVABILITY OUTPUTS
#==============================================================================

output "log_group_name" {
  description = "CloudWatch log group name for the application"
  value       = module.platform.log_group_name
}
