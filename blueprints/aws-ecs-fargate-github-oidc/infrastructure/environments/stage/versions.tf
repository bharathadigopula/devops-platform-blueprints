#==============================================================================
# TERRAFORM VERSION CONFIGURATION
#==============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.49"
    }
  }
}

#==============================================================================
# ENVIRONMENT LOCAL VALUES
#==============================================================================

locals {
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
# AWS PROVIDER CONFIGURATION
#==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
