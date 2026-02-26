# Elastic Beanstalk Deployment Guide

## Quick Start

Follow these steps to deploy the infrastructure:

### Step 1: Prepare Prerequisites

Before starting, gather these values:

```bash
# 1. Get your VPC ID
aws ec2 describe-vpcs --region ap-south-1 \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# 2. Get your subnet IDs (private and public)
aws ec2 describe-subnets --region ap-south-1 \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# 3. Get your ACM certificate ARN
aws acm list-certificates --region ap-south-1 \
  --query 'CertificateSummaryList[*].[CertificateArn,DomainName]' \
  --output table

# 4. Create S3 bucket for application code
aws s3 mb s3://my-app-source-bucket --region ap-south-1

# 5. Upload your WAR file to S3
aws s3 cp path/to/your/app.war s3://my-app-source-bucket/app.war

# 6. Verify upload
aws s3 ls s3://my-app-source-bucket/
```

### Step 2: Update Configuration

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
# OR
vim terraform.tfvars
```

**Key values to update:**
- `vpc_id` - Your VPC ID
- `private_subnets` - List of private subnet IDs
- `public_subnets` - List of public subnet IDs
- `custom_domain` - Your domain (uat.test.com)
- `acm_certificate_arn` - Your ACM certificate ARN
- `source_code_bucket` - Your S3 bucket name
- `source_code_key` - Path to WAR file in S3

### Step 3: Initialize Terraform

```bash
terraform init
```

**Output:**
```
Initializing the backend...
Initializing provider plugins...
...
Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

### Step 5: Plan Deployment

```bash
terraform plan -out=tfplan
```

**Review the plan carefully:**
- Look for ~15-20 resources to be created
- Verify IAM roles and policies are correct
- Check security group configurations

### Step 6: Apply Configuration

```bash
terraform apply tfplan
```

**Expected output after ~15-20 minutes:**
```
Outputs:

beanstalk_app_name = "java-tomcat-app"
beanstalk_env_name = "java-tomcat-uat"
beanstalk_env_cname = "java-tomcat-uat-123456789.ap-south-1.elasticbeanstalk.amazonaws.com"
...
```

### Step 7: Configure DNS

If you provided `route53_hosted_zone_id` in your `terraform.tfvars`, an
alias record should already have been created automatically. You can
verify with:

```bash
terraform output route53_alias_record_name
terraform output route53_alias_record_fqdn
```

If you did not supply a hosted zone ID (or prefer manual control) then
follow these commands as before:

```bash
# Get the Beanstalk CNAME
BEANSTALK_CNAME=$(terraform output -raw beanstalk_env_cname)
echo "CNAME to point to: $BEANSTALK_CNAME"

# Create CNAME record in Route 53
aws route53 change-resource-record-sets \
  --hosted-zone-id <YOUR-HOSTED-ZONE-ID> \
  --change-batch "{\"Changes\":[{\"Action\":\"CREATE\",\"ResourceRecordSet\":{\"Name\":\"uat.test.com\",\"Type\":\"CNAME\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$BEANSTALK_CNAME\"}]}}]}"
```

### Step 8: Wait for DNS Propagation

```bash
# Check if DNS is resolving (wait up to 5 minutes)
nslookup uat.test.com

# Once DNS is configured, verify the application
curl -k https://uat.test.com/
```

---

## Detailed Configuration

### Understanding the Infrastructure

```
┌─────────────────────────────────────────────────────┐
│                  AWS Region: ap-south-1              │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │  VPC (vpc-xxxxxxxxxxxxxxx)                   │   │
│  │                                              │   │
│  │  Public Subnets (for ALB)                    │   │
│  │  ┌────────────────┐  ┌────────────────┐    │   │
│  │  │ Subnet AZ-1a   │  │ Subnet AZ-1b   │    │   │
│  │  │                │  │                │    │   │
│  │  │ ┌────────────┐ │  │ ┌────────────┐ │    │   │
│  │  │ │  ALB       │ │  │ │  ALB       │ │    │   │
│  │  │ │:80 → :443  │ │  │ │:80 → :443  │ │    │   │
│  │  │ └────────────┘ │  │ └────────────┘ │    │   │
│  │  └────────────────┘  └────────────────┘    │   │
│  │          │                   │               │   │
│  │          └───────┬───────────┘               │   │
│  │                  │                           │   │
│  │  Private Subnets (for EC2)                  │   │
│  │  ┌────────────────┐  ┌────────────────┐    │   │
│  │  │ Subnet AZ-1a   │  │ Subnet AZ-1b   │    │   │
│  │  │                │  │                │    │   │
│  │  │ ┌────────────┐ │  │ ┌────────────┐ │    │   │
│  │  │ │ EC2 × 1    │◄─┼──│ EC2 × 1    │ │    │   │
│  │  │ │ Tomcat 9   │ │  │ │ Tomcat 9   │ │    │   │
│  │  │ │ Java 11    │ │  │ │ Java 11    │ │    │   │
│  │  │ └────────────┘ │  │ └────────────┘ │    │   │
│  │  └────────────────┘  └────────────────┘    │   │
│  │          │ ↑           │ ↑                   │   │
│  │          │ └───NAT Gateway─────┘            │   │
│  │          │ (for internet access)            │   │
│  │  (Auto-scaling: min=2, max=4)               │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  Route 53                                            │
│  uat.test.com (CNAME) ──→ ALB CNAME               │
└─────────────────────────────────────────────────────┘
```

### VPC and Network Configuration

```hcl
# Private subnets for EC2 instances
# - Instances don't have direct internet access
# - Access internet via NAT Gateway
# - Only accessible from ALB or bastion host
private_subnets = [
  "subnet-xxxxxxxxxxxxxxx",  # AZ-1a
  "subnet-xxxxxxxxxxxxxxx"   # AZ-1b
]

# Public subnets for Application Load Balancer
# - ALB is internet-facing
# - Receives traffic on ports 80 and 443
public_subnets = [
  "subnet-xxxxxxxxxxxxxxx",  # AZ-1a
  "subnet-xxxxxxxxxxxxxxx"   # AZ-1b
]
```

### SSL/TLS Configuration

```hcl
# HTTPS listener on port 443
# - Uses ACM certificate for encryption
# - Security policy: TLS 1.2+

# HTTP listener on port 80
# - Automatically redirects to HTTPS
# - Ensures all traffic is encrypted

acm_certificate_arn = "arn:aws:acm:ap-south-1:123456789012:certificate/xxx"
custom_domain = "uat.test.com"
enable_https_redirect = true
```

### Health Check Configuration

```hcl
# ALB checks application health every 30 seconds
# - Path: / (root of application)
# - Healthy threshold: 3 consecutive successes
# - Unhealthy threshold: 5 consecutive failures
# - Timeout: 5 seconds to respond

health_check_path = "/"
health_check_interval = 30
healthy_threshold = 3
unhealthy_threshold = 5
health_check_timeout = 5
```

### Auto-Scaling Configuration

```hcl
# Initial instances
desired_capacity = 2

# Scaling limits
min_size = 2  # Always maintain at least 2 instances
max_size = 4  # Never exceed 4 instances

# Scaling trigger: CPU Utilization
# - Scale up when CPU > 70% for 1 data point
# - Scale down when CPU < 30% for 1 data point

instance_type = "t3.medium"  # 2 vCPU, 4GB RAM
```

### Application Configuration

```hcl
# Java runtime settings
JAVA_OPTS = "-Xmx512m -Xms256m"
# - -Xmx512m: Max heap size
# - -Xms256m: Initial heap size

# Application server
# - Tomcat 9
# - Java 11 (Corretto)
# - Deployment format: WAR file in S3

solution_stack_name = "64bit Amazon Linux 2 v5.8.2 running Tomcat 9 Corretto 11"
```

---

## IAM Roles and Permissions

### EC2 Instance Role (`ecsInstanceRole`)

**Permissions granted:**
- S3: Read access to application source code and write access to logs
- SSM: Systems Manager access for debugging
- SQS: For async message processing (optional)

**Policy attachments:**
- `AmazonSSMManagedInstanceCore` - EC2 Systems Manager
- `AmazonS3FullAccess` - S3 bucket access
# CloudWatch policy removed (logging disabled)
- `AWSElasticBeanstalkWorkerTier` - Beanstalk operations
- `AmazonSQSFullAccess` - SQS for workers

### Elastic Beanstalk Service Role (`ecsServiceRole`)

**Permissions granted:**
- Allow Beanstalk service to manage environments
- Allow Auto Scaling to scale instances
- Allow EC2 instance creation and termination

**Policy attachments:**
- `AWSElasticBeanstalkEnhancedHealth` - Health monitoring
- `AWSElasticBeanstalkService` - Service operations
- `aws-elasticbeanstalk-service-role` - Auto Scaling

---

## Monitoring and Troubleshooting

### Check Environment Status

```bash
aws elasticbeanstalk describe-environments \
  --application-name java-tomcat-app \
  --region ap-south-1 \
  --query 'Environments[0].[EnvironmentName,Status,Health]'
```

### View Application Logs

```bash
# Real-time log tail
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/eb-activity.log \
  --follow --region ap-south-1

# Tomcat application logs
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/tomcat/catalina.out \
  --follow --region ap-south-1
```

### Check EC2 Instances

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### Check Load Balancer Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/awseb-STICKINESS-... \
  --region ap-south-1
```

---

## Deployment Verification Checklist

After deployment, verify:

- [ ] Elastic Beanstalk application created
- [ ] Elastic Beanstalk environment green/healthy
- [ ] 2 EC2 instances running in private subnets
- [ ] Application Load Balancer registered targets show healthy
- [ ] Security groups allow traffic on 80 and 443
# [ ] CloudWatch logs being collected (disabled by configuration)
- [ ] Application accessible via Beanstalk CNAME (before DNS)
- [ ] Application accessible via custom domain (after DNS)
- [ ] HTTPS redirect working (HTTP → HTTPS)
- [ ] Health checks passing
- [ ] Auto-scaling policies in place

---

## Common Issues and Solutions

### Issue: Environment is RED/Unhealthy

```bash
# Check detailed health status
aws elasticbeanstalk describe-environment-health \
  --environment-name java-tomcat-uat \
  --attribute-name All \
  --region ap-south-1

# Check recent events
aws elasticbeanstalk describe-events \
  --application-name java-tomcat-app \
  --max-records 50 \
  --region ap-south-1 | grep -A 5 "java-tomcat-uat"
```

**Common causes and solutions:**
1. **Invalid WAR file**: Re-upload valid WAR to S3
2. **Port 80 not open on instance**: Check security groups
3. **Application not responding on port 80**: Check Tomcat logs
4. **Health check path doesn't exist**: Adjust health check path
5. **Insufficient IAM permissions**: Verify EC2 instance role policies

### Issue: Instances Keep Restarting

```bash
# Check logs on instance
aws ssm start-session --target i-xxxxxxxxxxxxxxxx
tail -f /var/log/eb-activity.log
tail -f /var/log/tomcat/catalina.out
```

**Common causes:**
- Out of memory (increase max heap size)
- Application errors (check catalina.out)
- Invalid configuration

### Issue: DNS Not Resolving

```bash
# Test DNS resolution
nslookup uat.test.com
dig uat.test.com

# Verify Route 53 record
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED-ZONE-ID> \
  --query 'ResourceRecordSets[?Name==`uat.test.com.`]'
```

**Solutions:**
- Wait up to 5 minutes for DNS propagation
- Verify Route 53 hosted zone is correct
- Check CNAME/ALIAS record configuration

---

## Scaling and Updates

### Manual Scaling

```bash
# Update desired capacity
aws elasticbeanstalk update-environment \
  --environment-name java-tomcat-uat \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=DesiredCapacity,Value=3 \
  --region ap-south-1
```

### Deploy New Application Version

```bash
# Upload new WAR
aws s3 cp new-app.war s3://my-app-source-bucket/app.war

# Create new app version
aws elasticbeanstalk create-application-version \
  --application-name java-tomcat-app \
  --source-bundle S3Bucket=my-app-source-bucket,S3Key=app.war \
  --version-label v2.0.0 \
  --region ap-south-1

# Deploy new version
aws elasticbeanstalk update-environment \
  --environment-name java-tomcat-uat \
  --version-label v2.0.0 \
  --region ap-south-1
```

---

## Destroying Infrastructure

```bash
# Preview what will be deleted
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm when prompted
```

---

## Cost Optimization Tips

1. **Use Reserved Instances**: For predictable workloads
2. **Adjust scaling policies**: Reduce max instances if not needed
3. **Right-size instances**: Use t3.small if t3.medium is overkill
4. **Use Spot Instances**: For non-critical environments
# 5. (Monitoring steps removed - CloudWatch disabled)
6. **Update application code**: More efficient code uses less resources

---

## Support and Further Help

- AWS Beanstalk Docs: https://docs.aws.amazon.com/elasticbeanstalk/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest
- Java/Tomcat Platform: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/java-tomcat-platform.html
- AWS Support: https://console.aws.amazon.com/support/
