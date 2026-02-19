name = "uat-application"

environment_name = "uat-environment"
application_name = "uat-application"
solution_stack_name = "aws-elasticbeanstalk-amzn-2023.8.20250721.64bit-eb_corretto21_amazon_linux_2023-hvm-2025-07-30T21-04-20.635Z"
environment_tier = "WebServer"
instance_type = "t3.micro"
image_id = "ami-00163c375950510ff"
vpc_id = "vpc-0123456789abcdef0"
private_subnets = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
public_subnets = ["subnet-0a1b2c3d4e5f6g7h8", "subnet-0h8g7f6e5d4c3b21"]
associate_public_ip_address = true
load_balancer_type = "application"
min_instances = 1
max_instances = 1
iam_instance_profile = "arn:aws:iam::123456789012:instance-profile/your-instance-profile-name" 
ssl_certificate_arn = "value"
health_check_path = "/health"