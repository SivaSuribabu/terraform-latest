# ============================================================================
# ROOT MODULE - OUTPUTS
# ============================================================================
# These outputs expose the infrastructure details and are useful for:
# - Reference in the terraform.tfstate file
# - Console display after apply
# - Input to other infrastructure or monitoring tools

# ============================================================================
# ELASTIC BEANSTALK APPLICATION OUTPUTS
# ============================================================================

output "beanstalk_app_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = module.beanstalk_app.app_name
}

output "beanstalk_app_arn" {
  description = "ARN of the Elastic Beanstalk application"
  value       = module.beanstalk_app.app_arn
}

# ============================================================================
# ELASTIC BEANSTALK ENVIRONMENT OUTPUTS
# ============================================================================

output "beanstalk_env_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = module.beanstalk_env.env_name
}

output "beanstalk_env_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = module.beanstalk_env.env_id
}

# The CNAME is the internal load balancer endpoint
# Note: This is NOT the same as the custom domain
# You need to create a CNAME or ALIAS record in Route 53 pointing to this
output "beanstalk_env_cname" {
  description = "CNAME (load balancer endpoint) of the Elastic Beanstalk environment"
  value       = module.beanstalk_env.env_cname
  
  sensitive   = false
}

output "beanstalk_env_arn" {
  description = "ARN of the Elastic Beanstalk environment"
  value       = module.beanstalk_env.env_arn
}

# ============================================================================
# LOAD BALANCER OUTPUTS
# ============================================================================

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.beanstalk_env.load_balancer_dns
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group managing EC2 instances"
  value       = module.beanstalk_env.asg_name
}

# ============================================================================
# IAM ROLE OUTPUTS
# ============================================================================

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.beanstalk_app.instance_profile_name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = module.beanstalk_app.instance_profile_arn
}

output "instance_role_name" {
  description = "Name of the EC2 IAM role"
  value       = module.beanstalk_app.instance_role_name
}

output "instance_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.beanstalk_app.instance_role_arn
}

output "service_role_name" {
  description = "Name of the Elastic Beanstalk service role"
  value       = module.beanstalk_app.service_role_name
}

output "service_role_arn" {
  description = "ARN of the Elastic Beanstalk service role"
  value       = module.beanstalk_app.service_role_arn
}

# ============================================================================
# APPLICATION DEPLOYMENT OUTPUTS
# ============================================================================

output "application_version_deployed" {
  description = "Current application version deployed to the environment"
  value       = module.beanstalk_env.app_version
}

# ============================================================================
# CUSTOM DOMAIN AND URL INFORMATION
# ============================================================================
# Instructions for DNS configuration

# compute the DNS instruction once using locals to keep the output clean
locals {
  dns_instruction = (
    var.route53_hosted_zone_id != "" ?
      format(
        "Terraform has created an A alias record in Route53 (zone %s) pointing %s to the ALB.",
        var.route53_hosted_zone_id,
        var.custom_domain
      ) :
      format(
        "Create a CNAME record in Route53: '%s' -> '%s' (or use ALIAS record pointing to ALB)",
        var.custom_domain,
        module.beanstalk_env.env_cname
      )
  )
}

output "dns_configuration_info" {
  description = "Information for configuring custom domain DNS"
  value = {
    custom_domain    = var.custom_domain
    beanstalk_cname  = module.beanstalk_env.env_cname
    alb_dns_name     = module.beanstalk_env.load_balancer_dns
    route53_zone     = var.route53_hosted_zone_id
    instruction      = local.dns_instruction
    acm_certificate  = var.acm_certificate_arn
  }
  sensitive = false
}

# optional outputs for the alias record
output "route53_alias_record_name" {
  description = "Name of the Route53 alias record created (if any)"
  value       = aws_route53_record.custom_domain_alias.*.name
}

output "route53_alias_record_fqdn" {
  description = "FQDN of the Route53 alias record"
  value       = aws_route53_record.custom_domain_alias.*.fqdn
}

# ============================================================================
# ACCESS INFORMATION
# ============================================================================

output "access_url_via_elb_endpoint" {
  description = "Access the application via Elastic Beanstalk endpoint"
  value       = "https://${module.beanstalk_env.env_cname}"
}

output "access_url_via_custom_domain" {
  description = "Access the application via custom domain (after DNS configuration)"
  value       = "https://${var.custom_domain}"
}

# ============================================================================
# SUMMARY OUTPUT
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    application_name          = module.beanstalk_app.app_name
    environment_name          = module.beanstalk_env.env_name
    custom_domain             = var.custom_domain
    instance_type             = var.instance_type
    min_instances             = var.min_size
    max_instances             = var.max_size
    current_instances         = var.desired_capacity
    deployment_region         = var.aws_region
    solution_stack            = var.solution_stack_name
    next_step                 = "Update Route53 DNS to point '${var.custom_domain}' to '${module.beanstalk_env.env_cname}'"
  }
}
