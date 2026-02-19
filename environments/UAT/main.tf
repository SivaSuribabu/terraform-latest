module "vpc" {
  source            = "../../modules/vpc"
  vpc_cidr          = "10.10.0.0/16"
  azs               = ["us-east-1a", "us-east-1b"]
  public_subnets    = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets   = ["10.10.10.0/24", "10.10.20.0/24"]
  environment_name  = "uat"
}

module "security_groups" {
  source           = "../../modules/security-groups"
  vpc_id           = module.vpc.vpc_id
  environment_name = "uat"
}

module "beanstalk_env" {
  source               = "../../modules/beanstalk-environment"
  app_name             = "monolith-app"
  artifact_bucket      = "monolith-artifacts"
  build_number         = var.build_number
  environment_color    = var.environment_color
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  security_group_ids   = [module.security_groups.beanstalk_sg_id]
}