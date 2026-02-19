# Elastic Beanstalk Environment with full configuration

resource "aws_elastic_beanstalk_environment" "app" {
    name                = var.environment_name
    application         = var.application_name
    solution_stack_name = var.solution_stack_name
    tier                = var.environment_tier

    # VPC Configuration

    # Load Balancer

    setting {
        namespace = "aws:ec2:vpc"
        name      = "VPCId"
        value     = var.vpc_id
    }

    setting {
        namespace = "aws:ec2:vpc"
        name      = "Subnets"
        value     = join(",", var.private_subnets)
    }

    setting {
        namespace = "aws:ec2:vpc"
        name      = "ELBSubnets"
        value     = join(",", var.public_subnets)
    }

    # Auto Scaling Group
    setting {
        namespace = "aws:autoscaling:asg"
        name      = "MinSize"
        value     = var.min_instances
    }

    setting {
        namespace = "aws:autoscaling:asg"
        name      = "MaxSize"
        value     = var.max_instances
    }

    # Launch Configuration
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "InstanceType"
        value     = var.instance_type
    }

    setting{
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "Instancetypes"
        value     = var.instance_type
    }

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "ImageId"
        value     = var.image_id
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = var.iam_instance_profile
    }

    setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = join(",", var.security_groups)
    }

    # Load Balancer Configuration
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "LoadBalancerType"
        value     = var.load_balancer_type
    }

    setting {
        namespace = "aws:elbv2:listener:default"
        name      = "Protocol"
        value     = var.load_balancer_protocol
    }

    setting {
        namespace = "aws:elasticbeanstalk:application"
        name      = "Application Healthcheck URL"
        value     = var.health_check_path
    }

    setting {
      namespace = "aws:elbv2:listener:443"
      name      = "ListenerEnabled"
      value     = "true"
    }

    setting{
        namespace = "aws:elbv2:listener:443"
        name      = "SSLCertificateArns"
        value     = join(",",var.ssl_certificate_arns)
    }

    # Health Check
    setting {
        namespace = "aws:elasticbeanstalk:healthreporting:system"
        name      = "SystemType"
        value     = "Enhanced"
    }

    tags = var.tags
}