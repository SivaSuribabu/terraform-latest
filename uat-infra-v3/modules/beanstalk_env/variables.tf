# ============================================================================
# BEANSTALK ENVIRONMENT MODULE - VARIABLES
# ============================================================================
# These variables configure the Elastic Beanstalk environment, networking,
# health checks, scaling, and SSL/TLS settings

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "env_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
}

variable "solution_stack_name" {
  description = "Solution stack name for the environment (e.g., Java 11 with Tomcat)"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}

variable "service_role_arn" {
  description = "ARN of the Elastic Beanstalk service role"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "vpc_id" {
  description = "VPC ID for the Beanstalk environment"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs for the load balancer"
  type        = list(string)
}

variable "custom_domain" {
  description = "Custom domain name for the Beanstalk environment"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS/SSL"
  type        = string
}

variable "source_code_bucket" {
  description = "S3 bucket name containing the application source code"
  type        = string
}

variable "source_code_key" {
  description = "S3 object key for the application WAR file"
  type        = string
  default     = "app.war"
}

variable "health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
  default     = "/"
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures required to mark unreachable"
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "The amount of time, in seconds, between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, to wait for a health check response"
  type        = number
  default     = 5
}

variable "enable_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

# CloudWatch logging variables removed per user request.  Logging disabled.
variable "environment_name" {
  description = "Environment name for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
