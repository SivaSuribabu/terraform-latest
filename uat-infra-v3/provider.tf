# ============================================================================
# AWS PROVIDER CONFIGURATION
# ============================================================================
# This block configures the AWS provider with the specified region and tags
# that will be applied to all resources created by Terraform

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Default tags that will be applied to all AWS resources
  default_tags {
    tags = {
      Environment = var.environment_name
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedDate = timestamp()
    }
  }
}
