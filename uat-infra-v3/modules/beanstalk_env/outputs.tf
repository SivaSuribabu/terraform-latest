# ============================================================================
# BEANSTALK ENVIRONMENT MODULE - OUTPUTS
# ============================================================================
# These outputs expose the environment details to the root module
# and make them available for reference or further configuration

# Output the Elastic Beanstalk environment name
output "env_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.beanstalk_env.name
}

# Output the Elastic Beanstalk environment ID
output "env_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.beanstalk_env.id
}

# Output the CNAME (endpoint) of the Beanstalk environment
# This is the load balancer DNS name
output "env_cname" {
  description = "CNAME (endpoint) of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.beanstalk_env.cname
}

# Output the Elastic Beanstalk environment ARN
output "env_arn" {
  description = "ARN of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.beanstalk_env.arn
}

# Output the Auto Scaling Group name
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = length(aws_elastic_beanstalk_environment.beanstalk_env.autoscaling_groups) > 0 ? aws_elastic_beanstalk_environment.beanstalk_env.autoscaling_groups[0] : null
}

# Output the load balancer DNS name
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = length(aws_elastic_beanstalk_environment.beanstalk_env.load_balancers) > 0 ? aws_elastic_beanstalk_environment.beanstalk_env.load_balancers[0] : null
}

# Output the application version deployed
output "app_version" {
  description = "Current application version deployed"
  value       = aws_elastic_beanstalk_application_version.app_version.name
}
