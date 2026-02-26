# ============================================================================
# BEANSTALK ENVIRONMENT MODULE - MAIN
# ============================================================================
# This module creates and configures:
# 1. Elastic Beanstalk environment
# 2. Load balancer with HTTPS/SSL configuration
# 3. Auto-scaling configuration
# 4. Health check settings
# 5. Application deployment configuration

# ============================================================================
# ELASTIC BEANSTALK ENVIRONMENT
# ============================================================================
# Creates the Elastic Beanstalk environment with all necessary configurations
# This is where the actual application instances will run

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  # Name of the environment - must be unique within the application
  name = var.env_name

  # Reference to the Beanstalk application created in the app module
  application = var.app_name

  # Solution stack name specifies the platform (Java 11 + Tomcat)
  solution_stack_name = var.solution_stack_name

  # Environment tier specifies this is a web application (not a worker)
  tier = "WebServer"

  # Application version to deploy to this environment
  version_label = aws_elastic_beanstalk_application_version.app_version.name

  # =========================================================================
  # ENVIRONMENT CONFIGURATION OPTIONS
  # =========================================================================
  # These options configure various aspects of the environment

  # =========================================================================
  # INSTANCE PROFILE CONFIGURATION
  # =========================================================================
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.instance_profile_name
  }

  # =========================================================================
  # VPC AND NETWORKING CONFIGURATION
  # Deploys environment in the specified VPC
  # =========================================================================
  # VPC CONFIGURATION
  # =========================================================================
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

  # =========================================================================
  # HEALTH REPORTING
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "Enhanced"
  }

  # =========================================================================
  # LOAD BALANCER CONFIGURATION
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # =========================================================================
  # DEFAULT PROCESS CONFIGURATION (HTTP)
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "80"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = var.health_check_path
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = var.healthy_threshold
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = var.unhealthy_threshold
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = var.health_check_interval
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Timeout"
    value     = var.health_check_timeout
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "SuccessCodes"
    value     = "200,301,302"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "DeregistrationDelay"
    value     = "20"
  }

  # =========================================================================
  # HTTPS LISTENER CONFIGURATION (Port 443)
  # =========================================================================
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.acm_certificate_arn
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "InstanceProtocol"
    value     = "HTTP"
  }

  # =========================================================================
  # HTTP LISTENER CONFIGURATION (Port 80 - Redirect to HTTPS)
  # =========================================================================
  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "Protocol"
    value     = "HTTP"
  }

  # =========================================================================
  # AUTO-SCALING CONFIGURATION
  # =========================================================================
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(var.min_size)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(var.max_size)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "DesiredCapacity"
    value     = tostring(var.desired_capacity)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = "Any"
  }

  # =========================================================================
  # AUTO-SCALING TRIGGER (CPU-based)
  # =========================================================================
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "70"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "30"
  }

  # =========================================================================
  # EC2 INSTANCE CONFIGURATION
  # =========================================================================
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instance_type
  }

  # =========================================================================
  # ENVIRONMENT CONFIGURATION
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.service_role_arn
  }

  # CloudWatch logs configuration removed as per request.
  # =========================================================================
  # JAVA/TOMCAT OPTIONS
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JAVA_OPTS"
    value     = "-Xmx512m -Xms256m"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "none"
  }

  # =========================================================================
  # DEPLOYMENT OPTIONS
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "50"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "RollingWithAdditionalBatch"
  }

  # =========================================================================
  # APPLICATION ENVIRONMENT VARIABLES
  # =========================================================================
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CUSTOM_DOMAIN"
    value     = var.custom_domain
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SOURCE_BUCKET"
    value     = var.source_code_bucket
  }

  tags = merge(
    {
      Name = var.env_name
    },
    var.tags
  )

  depends_on = []
}

# ============================================================================
# APPLICATION VERSION
# ============================================================================
# Creates an application version that references the source code in S3
# This version will be deployed to the environment

resource "aws_elastic_beanstalk_application_version" "app_version" {
  # Unique version label for this application version
  name        = "${var.app_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  application = var.app_name
  description = "Application version from S3: ${var.source_code_bucket}/${var.source_code_key}"

  # S3 bucket and key where the application code is stored
  bucket = var.source_code_bucket
  key    = var.source_code_key

  # Automatically delete this version when it's no longer used
  force_delete = false

  tags = merge(
    {
      Name = "${var.app_name}-version"
    },
    var.tags
  )
}