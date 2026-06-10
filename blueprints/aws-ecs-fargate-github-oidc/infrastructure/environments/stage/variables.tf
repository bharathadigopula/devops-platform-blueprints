#==============================================================================
# AWS VARIABLES
#==============================================================================

variable "aws_region" {
  description = "AWS region for workload resources"
  type        = string
  default     = "us-east-1"
}

#==============================================================================
# PROJECT VARIABLES
#==============================================================================

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "ecs-fargate-oidc"
}

variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
  default     = "stage"
}

variable "name_prefix" {
  description = "Optional explicit name prefix for resources"
  type        = string
  default     = null
}

#==============================================================================
# NETWORK VARIABLES
#==============================================================================

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for private ECS task internet egress"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create ECR, CloudWatch Logs, and S3 VPC endpoints for private ECS task access"
  type        = bool
  default     = true
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks allowed to reach the public ALB on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

#==============================================================================
# APPLICATION VARIABLES
#==============================================================================

variable "container_image_tag" {
  description = "Image tag deployed from ECR"
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for the service"
  type        = bool
  default     = false
}

#==============================================================================
# OPERATIONS VARIABLES
#==============================================================================

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 60
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = true
}

variable "force_delete_ecr" {
  description = "Allow Terraform to delete the ECR repository even when images exist"
  type        = bool
  default     = false
}

variable "create_ecr_kms_key" {
  description = "Create a KMS key for ECR encryption when ecr_kms_key_arn is not provided"
  type        = bool
  default     = true
}

#==============================================================================
# TAG VARIABLES
#==============================================================================

variable "tags" {
  description = "Additional tags for all workload resources"
  type        = map(string)
  default     = {}
}
