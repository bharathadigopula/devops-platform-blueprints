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
# AWS PROVIDER CONFIGURATION
#==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
