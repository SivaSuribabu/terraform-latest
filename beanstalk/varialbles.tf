variable "region" {
  description = "This is region"
  type= string
  default = "ap-south-1"
}

variable "name" {
  description = "This is an uat-application"
    type= string
}

variable "environment_name" {
  description = "Thisis an uat-environment"
    type= string
}

variable "application_name" {
  description = "This is an uat-application"
    type= string
}
variable "solution_stack_name" {
  description = "This is an solution stack name"
    type= string
}
variable "environment_tier" {
  description = "This is an environment tier"
    type= string
}
variable "instance_type" {
  description = "This is an instance type"
    type= string
}
variable "image_id" {
  description = "This is an image id"
    type= string
}
variable "vpc_id" {
    description = "The ID of the VPC to use for the Elastic Beanstalk environment."
    type        = string
}
variable "private_subnets" {
    description = "A list of private subnet IDs for the Elastic Beanstalk environment."
    type        = list(string)
}
variable "public_subnets" {
    description = "A list of public subnet IDs for the Elastic Beanstalk environment."
    type        = list(string)
}
variable "associate_public_ip_address" {
    description = "Whether to associate a public IP address with the Elastic Beanstalk environment instances."
    type        = bool
    default     = false
}
variable "load_balancer_type" {
    description = "The type of load balancer to use (e.g., 'application' or 'classic')."
    type        = string
}
variable "min_instances" {
    description = "The minimum number of instances for the Auto Scaling group."
    type        = number
}
variable "max_instances" {
    description = "The maximum number of instances for the Auto Scaling group."
    type        = number
}
variable "iam_instance_profile" {
    description = "The name of the IAM instance profile to associate with the Elastic Beanstalk environment instances."
    type        = string
}

variable "health_check_path" {
    description = "The path to use for health checks (e.g., '/')."
    type        = string
}

variable "security_groups" {
    description = "A list of security group IDs to associate with the Elastic Beanstalk environment instances."
    type        = list(string)
}

variable "Load_balancer_protocol" {
    description = "The protocol to use for the load balancer (e.g., 'HTTP' or 'HTTPS')."
    type        = string
}

variable "ssl_certificate_arn" {
    description = "The ARN of the SSL certificate to use for HTTPS listeners (if applicable)."
    type        = string
}

