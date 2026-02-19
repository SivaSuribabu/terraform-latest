variable "environment_name" {
  description = "The name of the Elastic Beanstalk environment."
  type        = string
}
variable "solution_stack_name" {
  description = "The solution stack to use for the Elastic Beanstalk environment."
  type        = string
}
variable "application_name" {
  description = "The name of the Elastic Beanstalk application."
  type        = string
  
}
variable "environment_tier" {
  description = "The tier of the Elastic Beanstalk environment (e.g., 'WebServer' or 'Worker')."
  type        = string
}
variable "instance_type" {
  description = "The EC2 instance type to use for the Elastic Beanstalk environment."
  type        = string
}
variable "image_id" {
  description = "The ID of the custom AMI to use for the Elastic Beanstalk environment."
  type        = string
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

variable "security_groups" {
    description = "A list of security group IDs to associate with the Elastic Beanstalk environment instances."
    type        = list(string)
}

variable "load_balancer_protocol" {
    description = "The protocol to use for the load balancer (e.g., 'HTTP' or 'HTTPS')."
    type        = string
    default     = "HTTPS"
}

variable "health_check_path" {
    description = "The path to use for the load balancer health check."
    type        = string
}

variable "tags" {
  description = "A map of tags to assign to the Elastic Beanstalk environment."
  type        = map(string)
}

variable "ssl_certificate_arns" {
    description = "A list of SSL certificate ARNs to associate with the load balancer."
    type        = list(string)
}

variable "load_balancer_protocol_port" {
    description = "The port to use for the load balancer protocol (e.g., 80 for HTTP or 443 for HTTPS)."
    type        = number
    default     = 443
  
}