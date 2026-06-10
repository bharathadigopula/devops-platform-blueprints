#==============================================================================
# AWS VARIABLES
#==============================================================================

variable "aws_region" {
  description = "AWS region for Terraform state backend resources"
  type        = string
  default     = "us-east-1"
}

#==============================================================================
# PROJECT VARIABLES
#==============================================================================

variable "project_name" {
  description = "Project name used for state backend resource naming and tagging"
  type        = string
  default     = "ecs-fargate-oidc"
}

variable "environment" {
  description = "Environment name used for state backend tagging"
  type        = string
  default     = "shared"
}

variable "state_name" {
  description = "State backend name used in S3 bucket, DynamoDB table, and KMS alias names"
  type        = string
  default     = "platform"
}

#==============================================================================
# STATE BACKEND VARIABLES
#==============================================================================

variable "state_bucket_name" {
  description = "Optional explicit S3 bucket name for Terraform state"
  type        = string
  default     = null
}

variable "lock_table_name" {
  description = "Optional explicit DynamoDB table name for Terraform state locks"
  type        = string
  default     = null
}

variable "force_destroy_state_bucket" {
  description = "Allow Terraform to delete state bucket objects when destroying the bucket"
  type        = bool
  default     = false
}

#==============================================================================
# TAG VARIABLES
#==============================================================================

variable "tags" {
  description = "Additional tags for state backend resources"
  type        = map(string)
  default     = {}
}
