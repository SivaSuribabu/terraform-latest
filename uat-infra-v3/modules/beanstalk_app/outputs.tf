# ============================================================================
# BEANSTALK APPLICATION MODULE - OUTPUTS
# ============================================================================
# These outputs expose the created resources to the root module
# and make them available for use in the environment module

# Output the Elastic Beanstalk application name
output "app_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.beanstalk_app.name
}

# Output the Elastic Beanstalk application ARN
output "app_arn" {
  description = "ARN of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.beanstalk_app.arn
}

# Output the EC2 instance profile name
# Used when creating the Beanstalk environment to attach to instances
output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ecsInstanceProfile.name
}

# Output the EC2 instance profile ARN
output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ecsInstanceProfile.arn
}

# Output the EC2 IAM role name
output "instance_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.ecsInstanceRole.name
}

# Output the EC2 IAM role ARN
output "instance_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ecsInstanceRole.arn
}

# Output the Elastic Beanstalk service role name
output "service_role_name" {
  description = "Name of the Elastic Beanstalk service role"
  value       = aws_iam_role.ecsServiceRole.name
}

# Output the Elastic Beanstalk service role ARN
output "service_role_arn" {
  description = "ARN of the Elastic Beanstalk service role"
  value       = aws_iam_role.ecsServiceRole.arn
}
