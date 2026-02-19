module "beanstalk_aplication" {
  source = "./modules/beanstalk_aplication"
  name   = var.name
}

#************************ This is the beanstalk environment block ************************
module "beanstalk_env" {
  source                  = "./modules/beanstalk_env"
  vpc_id                  = var.vpc_id
  application_name        = var.application_name
  environment_name        = var.environment_name
  environment_tier        = var.environment_tier
  solution_stack_name     = var.solution_stack_name
  instance_type           = var.instance_type
  min_instances           = var.min_instances
  max_instances           = var.max_instances
  image_id                = var.image_id
  iam_instance_profile    = var.iam_instance_profile
  security_groups         = var.security_groups
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  load_balancer_type      = var.load_balancer_type
  health_check_path       = var.health_check_path
  ssl_certificate_arns    = var.ssl_certificate_arns
  DB_HOST                 = var.DB_HOST
  tags                    = var.tags
}
