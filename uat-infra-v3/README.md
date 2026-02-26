# Elastic Beanstalk Infrastructure on AWS - Terraform Guide

## Overview

This Terraform configuration deploys a complete, production-ready Elastic Beanstalk infrastructure with:

- **Java 11 + Tomcat** application runtime
- **Application Load Balancer** (ALB) with HTTPS/SSL
- **Auto-scaling** based on CPU utilization
- **Private EC2 instances** in VPC for security
- **Health checks** and monitoring
- **Monitoring** integration (logs may be disabled)
- **IAM roles and policies** for secure access

---

## Prerequisites

Before applying this Terraform configuration, ensure you have:

### 1. AWS Account Setup
- [ ] AWS Account with appropriate IAM permissions
- [ ] AWS CLI configured with credentials
- [ ] Terraform installed (version >= 1.0)

### 2. VPC and Network Infrastructure
- [ ] VPC created in ap-south-1 region
- [ ] At least 2 private subnets for EC2 instances
- [ ] At least 2 public subnets for ALB
- [ ] Internet Gateway attached to VPC
- [ ] NAT Gateway in public subnets (for EC2 instances to access internet)

### 3. SSL/TLS Certificate
- [ ] AWS Certificate Manager (ACM) certificate created for your domain
- [ ] Certificate ARN noted (format: `arn:aws:acm:ap-south-1:ACCOUNT-ID:certificate/ID`)
- [ ] Domain: `uat.test.com` (or your custom domain)

### 4. Application Source Code
- [ ] S3 bucket created in ap-south-1 region
- [ ] Application WAR file uploaded to S3
- [ ] S3 bucket allows Beanstalk EC2 instances to read files
- [ ] Bucket name and WAR file path (key) noted

### 5. Terraform Backend
- [ ] S3 bucket for Terraform state: `uat-terraform-state-bucket`
- [ ] DynamoDB table for state locking: `terraform-state-lock`
- [ ] Both resources should be in the same region (ap-south-1)

---

## Directory Structure

```
uat-infra-v3/
├── backend.tf                      # Terraform backend configuration (S3 + DynamoDB)
├── provider.tf                     # AWS provider configuration
├── variables.tf                    # Root-level variables definition
├── main.tf                         # Root module - orchestrates other modules
├── outputs.tf                      # Output values from infrastructure
├── terraform.tfvars                # Variable values (Replace with your values)
│
└── modules/
    ├── beanstalk_app/             # Module: Beanstalk app + IAM roles
    │   ├── main.tf                # Creates app, IAM roles, instance profiles
    │   ├── variables.tf           # Module-specific variables
    │   └── outputs.tf             # Module outputs
    │
    └── beanstalk_env/             # Module: Beanstalk environment
        ├── main.tf                # Creates environment, ALB, auto-scaling
        ├── variables.tf           # Module-specific variables
        └── outputs.tf             # Module outputs
```

---

## Configuration

### 1. Update terraform.tfvars

First, update the `terraform.tfvars` file with your actual values:

```hcl
aws_region          = "ap-south-1"
project_name        = "uat-infra"
environment_name    = "uat"
app_name            = "java-tomcat-app"
env_name            = "java-tomcat-uat"

# Replace with your actual VPC and subnet IDs
vpc_id              = "vpc-xxxxxxxxxxxxxxx"
private_subnets     = ["subnet-xxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxx"]
public_subnets      = ["subnet-xxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxx"]

# Replace with your domain and certificate
custom_domain       = "uat.test.com"
acm_certificate_arn = "arn:aws:acm:ap-south-1:123456789012:certificate/xxx"

# Replace with your S3 bucket details
source_code_bucket  = "my-app-source-bucket"
source_code_key     = "app.war"
```

### 2. Find Your VPC and Subnet IDs

```bash
# List VPCs
aws ec2 describe-vpcs --region ap-south-1 --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]'

# List subnets for a specific VPC
aws ec2 describe-subnets --region ap-south-1 \
  --filters "Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]'
```

### 3. Find Your ACM Certificate ARN

```bash
# List ACM certificates
aws acm list-certificates --region ap-south-1 --query 'CertificateSummaryList[*].[CertificateArn,DomainName]'
```

### 4. Create and Upload WAR File to S3

```bash
# Create S3 bucket (if not exists)
aws s3 mb s3://my-app-source-bucket --region ap-south-1

# Upload WAR file
aws s3 cp target/app.war s3://my-app-source-bucket/app.war

# Verify upload
aws s3 ls s3://my-app-source-bucket/
```

---

## Infrastructure Components

### 1. Elastic Beanstalk Application (`beanstalk_app` module)

**What it creates:**
- Elastic Beanstalk application container
- IAM role for EC2 instances (`ecsInstanceRole`)
  - Permissions for Beanstalk agent
  - S3 access for source code and logs
  - (Optional) CloudWatch access for metrics and logs - removed if logging disabled
  - SSM access for systems manager
  - SQS access for async processing
- IAM role for Elastic Beanstalk service (`ecsServiceRole`)
- EC2 instance profile

**Why:**
- Application role allows instances to interact with AWS services
- Service role allows Beanstalk to manage AWS resources on your behalf
- Instance profile is required for Beanstalk to launch EC2 instances

### 2. Elastic Beanstalk Environment (`beanstalk_env` module)

**What it creates:**
- Elastic Beanstalk environment with Java 11 + Tomcat
- Application Load Balancer (ALB)
  - HTTPS listener on port 443 with ACM certificate
  - HTTP listener on port 80 redirecting to HTTPS
- Auto-scaling group
  - Min instances: 2
  - Max instances: 4
  - Initial instances: 2
- Health checks configured
- Application version deployment

**Configuration Details:**

| Setting | Purpose |
|---------|---------|
| **VPC & Subnets** | EC2 instances in private subnets, ALB in public subnets |
| **Health Checks** | Monitors application every 30 seconds |
| **Auto-scaling** | Scales based on CPU utilization (70% up, 30% down) |
| **HTTPS/SSL** | Encrypts traffic using ACM certificate |
| **HTTP Redirect** | All HTTP traffic automatically redirected to HTTPS |
| **Logs** | Application logs (streaming optional, disabled by default) |

---

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd /home/suribabu/suribabu/terraform/UAT_INFRA/uat-infra-v3

terraform init
```

**What happens:**
- Downloads required Terraform providers (AWS provider)
- Initializes backend storage for state file
- Creates `.terraform` directory

### Step 2: Validate Configuration

```bash
terraform validate
```

**Expected output:** `Success! The configuration is valid.`

### Step 3: Plan Infrastructure

```bash
terraform plan -out=tfplan
```

**What to review:**
- Count of resources to be created (should be ~15-20 resources)
- Resource names and configurations
- IAM policies being attached
- No errors in the plan

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

**What happens:**
- Creates all resources in AWS
- Deployment takes ~15-20 minutes
- Outputs are displayed at the end

**Expected resources created:**
- 1 Elastic Beanstalk application
- 1 Elastic Beanstalk environment
- 1 Application Load Balancer
- 1 Auto Scaling Group
- 2-4 EC2 instances
- 2 IAM roles
- 1 Instance profile
- Multiple security groups and network configurations

### Step 5: Verify Deployment

```bash
# Get the Beanstalk environment CNAME
terraform output beanstalk_env_cname

# Check environment health
aws elasticbeanstalk describe-environments \
  --application-name java-tomcat-app \
  --region ap-south-1 \
  --query 'Environments[0].[EnvironmentName,Status,Health]'

# Check EC2 instances
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress]'
```

---

## DNS Configuration

Terraform can automatically create a Route53 alias record for your
custom domain if you supply the hosted zone ID. This saves you from
manually running AWS CLI commands after deployment. To enable this,
add the following variable to your `terraform.tfvars`:

```hcl
# optional; leave blank to manage DNS manually
route53_hosted_zone_id = "Z1234567890ABC"
```

When the value is non‑empty and `custom_domain` is set, the root module
will look up the underlying Application Load Balancer and create an
`A` record alias for you. The record name will equal `custom_domain`.

If you prefer to manage DNS yourself, the previous manual steps still
apply:

### Manual Option: Create CNAME / ALIAS Using AWS CLI

Use whichever method you like – CNAME to the Beanstalk environment
CNAME or an alias to the ALB. Here is an example using the CLI:

```bash
# get the Beanstalk CNAME
BEANSTALK_CNAME=$(terraform output beanstalk_env_cname)
# (or) get the load balancer DNS name
ALB_DNS=$(terraform output load_balancer_dns_name)

# create CNAME record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch "{\"Changes\":[{\"Action\":\"CREATE\",\"ResourceRecordSet\":{\"Name\":\"uat.test.com\",\"Type\":\"CNAME\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$BEANSTALK_CNAME\"}]}}]}"
```

Most users prefer an alias record pointing to the ALB for better
performance and zero‑TTL behaviour, but either option works.

---

## Accessing Your Application

After DNS is configured:

```bash
# Via custom domain (after DNS propagation)
https://uat.test.com

# Via Beanstalk endpoint
https://java-tomcat-uat.elasticbeanstalk.ap-south-1.amazonaws.com

# Check application logs
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/eb-activity.log --follow --region ap-south-1
```

---

## Application Deployment

### Deploying a New WAR File

```bash
# Upload new WAR file to S3
aws s3 cp target/new-app.war s3://my-app-source-bucket/app.war

# Redeploy (option 1: update source in terraform.tfvars and apply)
terraform apply

# OR via AWS CLI (option 2: direct deployment)
aws elasticbeanstalk create-application-version \
  --application-name java-tomcat-app \
  --source-bundle S3Bucket=my-app-source-bucket,S3Key=app.war \
  --version-label v1.1.0 \
  --region ap-south-1

aws elasticbeanstalk update-environment \
  --environment-name java-tomcat-uat \
  --version-label v1.1.0 \
  --region ap-south-1
```

---

## Monitoring and Logging

CloudWatch logging and metrics collection are currently disabled in this configuration. If you decide to enable them later, update the variables and policy attachments accordingly.

### Beanstalk Console

```bash
# Get environment details
aws elasticbeanstalk describe-environments \
  --application-name java-tomcat-app \
  --environment-names java-tomcat-uat \
  --region ap-south-1
```

### Beanstalk Console

```bash
# Get environment details
aws elasticbeanstalk describe-environments \
  --application-name java-tomcat-app \
  --environment-names java-tomcat-uat \
  --region ap-south-1
```

---

## Scaling Adjustments

### Modify Auto-scaling Limits

Edit `terraform.tfvars` and update:
```hcl
min_size           = 2  # Change if needed
max_size           = 4  # Change if needed
desired_capacity   = 2  # Change if needed
```

Then apply:
```bash
terraform apply
```

### Modify Scaling Triggers

In `modules/beanstalk_env/main.tf`, find the `aws:autoscaling:trigger` section and adjust:
```hcl
# Scale up threshold
{
  namespace = "aws:autoscaling:trigger"
  name      = "UpperThreshold"
  value     = "70"  # Change to 50 or 80 as needed
},
# Scale down threshold
{
  namespace = "aws:autoscaling:trigger"
  name      = "LowerThreshold"
  value     = "30"  # Change as needed
},
```

---

## Troubleshooting

### Environment Status is RED

```bash
# Check environment health details
aws elasticbeanstalk describe-environment-health \
  --environment-name java-tomcat-uat \
  --attribute-name All \
  --region ap-south-1

# View recent events
aws elasticbeanstalk describe-events \
  --environment-name java-tomcat-uat \
  --max-records 20 \
  --region ap-south-1
```

### Instances Not Starting

```bash
# Check EC2 instance status
aws ec2 describe-instance-status \
  --region ap-south-1 \
  --filters "Name=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat"

# Tail instance logs
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
tail -f /var/log/eb-activity.log
```

### Application Returning 502/503 Errors

```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/xxx \
  --region ap-south-1

# Check Tomcat logs
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/tomcat/catalina.out --follow
```

---

## Cleanup/Destruction

To destroy all created resources:

```bash
# Preview destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy
```

**Warning:** This will delete:
- Elastic Beanstalk environment and application
- All EC2 instances
- Load balancer
- Auto Scaling group
- IAM roles and instance profiles

The S3 bucket and state backend will NOT be deleted (must be done manually).

---

## Key Explanations

### Why Private Subnets for EC2?
- EC2 instances don't need direct internet access
- ALB in public subnets handles internet traffic
- Instances access internet through NAT Gateway
- Enhanced security (no instances exposed to internet)

### Why Health Checks?
- ALB verifies application is responding
- Automatically replaces unhealthy instances
- Ensures high availability

### Why Auto-scaling?
- Handles traffic spikes automatically
- Reduces costs during low traffic periods
- Maintains target capacity (#instances)

### Why Multiple Availability Zones?
- Minimum 2 AZs for high availability
- If one AZ goes down, application still runs
- Distributes load across zones

### Why HTTPS/SSL?
- Encrypts traffic between clients and ALB
- ACM certificate management automatic
- Compliance requirement (PCI-DSS, HIPAA)
- HTTP automatically redirected to HTTPS

---

## Security Best Practices Applied

✅ **Network Isolation**: Private EC2 instances, public ALB  
✅ **IAM Least Privilege**: Role-based access control  
✅ **Encryption in Transit**: HTTPS/SSL enforced  
✅ **Logging & Monitoring**: CloudWatch integration  
✅ **Auto-healing**: Health checks and replacement  
✅ **Security Groups**: Restrict traffic to necessary ports  
✅ **Versioning**: Application versions tracked  

---

## Additional Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Java 11 Tomcat Elastic Beanstalk Docs](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/java-tomcat-platform.html)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

---

## Support

For issues or questions:
1. Review CloudWatch logs
2. Check Beanstalk events in AWS Console
3. Verify prerequisites are met
4. Run `terraform validate` to check configuration
5. Review Terraform documentation
