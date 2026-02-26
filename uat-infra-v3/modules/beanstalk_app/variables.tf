# ============================================================================
# BEANSTALK APPLICATION MODULE - VARIABLES
# ============================================================================
# These variables are specific to the Beanstalk application and IAM configuration

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "description" {
  description = "Description of the Elastic Beanstalk application"
  type        = string
  default     = "Elastic Beanstalk Application"
}

variable "environment_name" {
  description = "Environment name for resource tagging"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
