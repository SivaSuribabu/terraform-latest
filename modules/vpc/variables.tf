variable "environment_name" {}
variable "vpc_cidr" {}
variable "azs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "enable_nat_gateway" {
  default = true
}