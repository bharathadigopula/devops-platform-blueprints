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
  default     = "dev"
}

variable "name_prefix" {
  description = "Optional explicit name prefix for resources"
  type        = string
  default     = null
}

#==============================================================================
# NETWORK VARIABLES
#==============================================================================

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for public and private subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public ALB subnets"
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private ECS task subnets"
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private ECS tasks can reach ECR and CloudWatch Logs"
  type        = bool
  default     = false
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks allowed to reach the public ALB on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

#==============================================================================
# APPLICATION VARIABLES
#==============================================================================

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

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
  default     = 30
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

variable "ecr_kms_key_arn" {
  description = "Existing KMS key ARN for ECR encryption"
  type        = string
  default     = null
}

#==============================================================================
# TAG VARIABLES
#==============================================================================

variable "tags" {
  description = "Additional tags for all workload resources"
  type        = map(string)
  default     = {}
}
