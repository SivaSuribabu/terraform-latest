# ============================================================================
# ROOT LEVEL VARIABLES
# ============================================================================
# These variables define the configuration for the Elastic Beanstalk
# infrastructure and are used across modules

# AWS region where resources will be deployed
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

# Project name for resource naming and tagging
variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "uat-infra"
}

# Environment name for resource naming and tagging
variable "environment_name" {
  description = "Environment name (dev, staging, uat, prod)"
  type        = string
  default     = "uat"
}

# Application name for Elastic Beanstalk application
variable "app_name" {
  description = "Elastic Beanstalk application name"
  type        = string
  default     = "java-tomcat-app"
}

# Environment name for Elastic Beanstalk environment
variable "env_name" {
  description = "Elastic Beanstalk environment name"
  type        = string
  default     = "java-tomcat-uat"
}

# Solution stack for Java 11 with Tomcat
variable "solution_stack_name" {
  description = "Elastic Beanstalk solution stack name (Java 11 with Tomcat)"
  type        = string
  default     = "64bit Amazon Linux 2 v5.8.2 running Tomcat 9 Corretto 11"
}

# Minimum number of EC2 instances for the Beanstalk environment
variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

# Maximum number of EC2 instances for the Beanstalk environment
variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

# Desired capacity (initial number of instances)
variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

# Instance type for EC2 instances in the Beanstalk environment
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

# VPC ID where Beanstalk environment will be deployed
variable "vpc_id" {
  description = "VPC ID for Beanstalk environment"
  type        = string
}

# List of private subnet IDs for the load balancer
variable "private_subnets" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

# List of public subnet IDs for the load balancer
variable "public_subnets" {
  description = "List of public subnet IDs for load balancer"
  type        = list(string)
}

# Custom domain name for the Beanstalk environment
variable "custom_domain" {
  description = "Custom domain name (e.g., uat.test.com)"
  type        = string
}

# Route53 hosted zone ID for automatic DNS record creation.
# When set (non‑empty), Terraform will create an A alias record
# pointing the custom_domain to the Beanstalk environment's
# Application Load Balancer DNS. Leave empty to manage DNS manually.
variable "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID containing the custom_domain (optional)"
  type        = string
  default     = ""
}

# ACM certificate ARN for HTTPS/SSL
variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

# S3 bucket name for application source code
variable "source_code_bucket" {
  description = "S3 bucket name containing application source code"
  type        = string
}

# S3 object key for the application WAR file
variable "source_code_key" {
  description = "S3 object key for the WAR file"
  type        = string
  default     = "app.war"
}

# Health check path for the EC2 instances
variable "health_check_path" {
  description = "Health check path for load balancer"
  type        = string
  default     = "/"
}

# Healthy threshold for load balancer health checks
variable "healthy_threshold" {
  description = "Healthy threshold for health checks"
  type        = number
  default     = 3
}

# Unhealthy threshold for load balancer health checks
variable "unhealthy_threshold" {
  description = "Unhealthy threshold for load balancer"
  type        = number
  default     = 5
}

# Health check interval in seconds
variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

# Health check timeout in seconds
variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

# Enable HTTPS redirect from HTTP traffic
variable "enable_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

# NOTE: CloudWatch logging has been disabled per request.  Variables formerly
# controlling logs removed.
