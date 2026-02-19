#************************ This is the beanstalk application block ************************
region = "ap-south-1"
app_name = "uat-application"

#************************ This is the beanstalk application block ************************

environment_name = "uat-environment"
application_name = "uat-application"
solution_stack_name = "aws-elasticbeanstalk-amzn-2023.8.20250721.64bit-eb_corretto11_amazon_linux_2023-hvm-2025-07-30T21-04-20.635Z"
environment_tier = "WebServer"
instance_type = "t3.micro" # Needs to be modified.
image_id = "ami-00163c375950510ff" # Needs to be modified.
vpc_id = "vpc-0123456789abcdef0" # Needs to be modified.
private_subnets = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"] # Needs to be modified.
public_subnets = ["subnet-0a1b2c3d4e5f6g7h8", "subnet-0h8g7f6e5d4c3b21"] # Needs to be modified.
associate_public_ip_address = true
load_balancer_type = "application"
min_instances = 1
max_instances = 1
iam_instance_profile = "arn:aws:iam::123456789012:instance-profile/your-instance-profile-name"  # Needs to be modified.
ssl_certificate_arns = ["arn:aws:acm:region:account-id:certificate/certificate-id"] # Needs to be modified.
health_check_path = "/health"
security_groups = ["sg-0123456789abcdef0", "sg-0fedcba9876543210"] # Needs to be modified.
Load_balancer_protocol = "HTTPS"
DB_HOST = "mydb.rds.com" # Needs to be modified.
tags = {
  Environment = "UAT"
  Project     = "uat-infra"
}
