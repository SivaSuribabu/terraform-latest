# ============================================================================
# TERRAFORM BACKEND CONFIGURATION
# ============================================================================
# This block configures the remote state storage for Terraform
# State is stored in an S3 bucket with DynamoDB locking enabled
# This prevents concurrent modifications and maintains consistency

terraform {
  backend "s3" {
    # S3 bucket name where the state file will be stored
    bucket = "ie-uat-infra"
    
    # Path to the state file within the bucket
    key    = "uat-infra/terraform.tfstate"
    
    # AWS region where the S3 bucket is located
    region = "ap-south-1"
    
    # Enable server-side encryption for the state file
    encrypt = true
    
    # S3 lockfile setting for state locking to prevent concurrent modifications
    use_lockfile = true
  }
}

# Note: Before applying this configuration, ensure:
# 1. The S3 bucket "uat-terraform-state-bucket" exists
# 2. The DynamoDB table "terraform-state-lock" exists with "LockID" as primary key
# 3. You have appropriate IAM permissions to access these resources
