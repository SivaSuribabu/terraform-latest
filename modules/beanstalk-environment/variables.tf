variable "app_name" {}
variable "artifact_bucket" {}
variable "build_number" {}
variable "environment_color" {}

variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}

variable "instance_type" {
  default = "t3.medium"
}

variable "min_size" {
  default = 2
}

variable "max_size" {
  default = 4
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}
