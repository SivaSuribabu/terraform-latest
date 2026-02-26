# ============================================================================
# ROOT MODULE - MAIN CONFIGURATION
# ============================================================================
# This file orchestrates the infrastructure by calling the modules
# and passing variables between them

# ============================================================================
# MODULE: ELASTIC BEANSTALK APPLICATION
# ============================================================================
# This module creates:
# - The Elastic Beanstalk application container
# - IAM roles for EC2 instances and Elastic Beanstalk service
# - Instance profiles for EC2 instances

module "beanstalk_app" {
  # Path to the Beanstalk application module
  source = "./modules/beanstalk_app"

  # Application name
  app_name = var.app_name

  # Description for the application
  description = "Java Tomcat Application for ${var.environment_name}"

  # Environment variables passed through
  environment_name = var.environment_name
  project_name     = var.project_name

  # Additional tags for the resources
  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }
}

# ============================================================================
# MODULE: ELASTIC BEANSTALK ENVIRONMENT
# ============================================================================
# This module creates:
# - Elastic Beanstalk environment with load balancer
# - Auto-scaling configuration
# - Health check settings
# - HTTPS/SSL configuration

module "beanstalk_env" {
  # Path to the Beanstalk environment module
  source = "./modules/beanstalk_env"

  # Application and environment names
  app_name = module.beanstalk_app.app_name
  env_name = var.env_name

  # Solution stack (Java 11 + Tomcat)
  solution_stack_name = var.solution_stack_name

  # IAM resources from the app module
  # Instance profile name is used to attach the IAM role to instances
  instance_profile_name = module.beanstalk_app.instance_profile_name

  # Service role ARN is used by Elastic Beanstalk service
  service_role_arn = module.beanstalk_app.service_role_arn

  # Scaling configuration
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  instance_type      = var.instance_type

  # Network configuration
  vpc_id           = var.vpc_id
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets

  # Custom domain and SSL/TLS
  custom_domain       = var.custom_domain
  acm_certificate_arn = var.acm_certificate_arn

  # Application source code location in S3
  source_code_bucket = var.source_code_bucket
  source_code_key    = var.source_code_key

  # Health check configuration
  health_check_path     = var.health_check_path
  healthy_threshold     = var.healthy_threshold
  unhealthy_threshold   = var.unhealthy_threshold
  health_check_interval = var.health_check_interval
  health_check_timeout  = var.health_check_timeout

  # HTTPS configuration
  enable_https_redirect   = var.enable_https_redirect

  # Environment and project names for tagging
  environment_name = var.environment_name
  project_name     = var.project_name

  # Additional tags
  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }

  # Ensure the app module resources are created first
  depends_on = [module.beanstalk_app]
}

# ---------------------------------------------------------------------------
# Optional DNS alias record in Route53
# If the user provides both custom_domain and route53_hosted_zone_id the
# configuration will create an A record alias pointing to the ALB that backs
# the Beanstalk environment. This eliminates the need to manually manage DNS.
# ---------------------------------------------------------------------------

locals {
  alb_dns = module.beanstalk_env.load_balancer_dns
}

# Get the hosted zone ID for ALB in the current region
data "aws_elb_hosted_zone_id" "alb" {}

resource "aws_route53_record" "custom_domain_alias" {
  count   = var.route53_hosted_zone_id != "" && var.custom_domain != "" ? 1 : 0
  zone_id = var.route53_hosted_zone_id
  name    = var.custom_domain
  type    = "A"
  alias {
    name                   = local.alb_dns
    zone_id                = data.aws_elb_hosted_zone_id.alb.id
    evaluate_target_health = true
  }
}
