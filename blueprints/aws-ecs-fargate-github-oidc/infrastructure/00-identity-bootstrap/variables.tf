#==============================================================================
# AWS VARIABLES
#==============================================================================

variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

#==============================================================================
# PROJECT VARIABLES
#==============================================================================

variable "project_name" {
  description = "Project name used for tagging and role naming"
  type        = string
  default     = "ecs-fargate-oidc"
}

variable "environment" {
  description = "Environment name used for tagging and role naming"
  type        = string
  default     = "dev"
}

variable "role_name" {
  description = "Optional explicit IAM role name for GitHub Actions"
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary ARN for the GitHub Actions role"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach to the GitHub Actions role"
  type        = list(string)
  default     = []
}

variable "create_blueprint_permissions_policy" {
  description = "Create and attach the scoped blueprint permissions policy to the GitHub Actions role"
  type        = bool
  default     = true
}

variable "enable_state_backend_permissions" {
  description = "Include Terraform state backend permissions in the blueprint policy"
  type        = bool
  default     = true
}

variable "enable_workload_permissions" {
  description = "Include ECS Fargate workload deployment permissions in the blueprint policy"
  type        = bool
  default     = true
}

#==============================================================================
# GITHUB TRUST VARIABLES
#==============================================================================

variable "github_owner" {
  description = "GitHub owner or organization allowed to assume the role"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the role"
  type        = string
  default     = "main"
}

#==============================================================================
# TAG VARIABLES
#==============================================================================

variable "tags" {
  description = "Additional tags for bootstrap resources"
  type        = map(string)
  default     = {}
}
