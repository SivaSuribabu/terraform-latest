resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name        = var.name
  description = "Elastic Beanstalk Application created by Terraform"
}