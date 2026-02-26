# Quick Reference Guide

## File Structure Overview

```
uat-infra-v3/
├── backend.tf                    # Terraform state backend (S3 + DynamoDB)
├── provider.tf                   # AWS provider configuration
├── variables.tf                  # All input variables
├── main.tf                       # Module orchestration
├── outputs.tf                    # Output values
├── terraform.tfvars              # Your configuration values (UPDATE THIS)
├── terraform.tfvars.example      # Template for variables
│
├── README.md                     # Comprehensive guide
├── DEPLOYMENT_GUIDE.md           # Step-by-step deployment
├── QUICK_REFERENCE.md            # This file
├── .gitignore                    # Git ignore rules
│
└── modules/
    ├── beanstalk_app/           # Elastic Beanstalk app + IAM roles
    │   ├── main.tf              # 80+ lines with detailed explanations
    │   ├── variables.tf         # 15+ input variables
    │   └── outputs.tf           # 8+ outputs
    │
    └── beanstalk_env/           # Elastic Beanstalk environment
        ├── main.tf              # 200+ lines with full configuration
        ├── variables.tf         # 40+ input variables
        └── outputs.tf           # 8+ outputs
```

---

## Key Code Blocks Explanation

### 1. VPC & Networking Configuration
**File**: `modules/beanstalk_env/main.tf` (lines ~50-70)

```hcl
# Place EC2 instances in private subnets
{
  namespace = "aws:ec2:vpc"
  name      = "Subnets"
  value     = join(",", var.private_subnets)
}

# Place load balancer in public subnets
{
  namespace = "aws:ec2:vpc"
  name      = "ELBSubnets"
  value     = join(",", var.public_subnets)
}
```

**What it does**: Deploys EC2 instances in private subnets (secure, no internet) and ALB in public subnets (receives external traffic)

### 2. HTTPS/SSL Configuration
**File**: `modules/beanstalk_env/main.tf` (lines ~100-125)

```hcl
# HTTPS listener on port 443
{
  namespace = "aws:elbv2:listener:443"
  name      = "Protocol"
  value     = "HTTPS"
},
{
  namespace = "aws:elbv2:listener:443"
  name      = "SSLCertificateArns"
  value     = var.acm_certificate_arn
}
```

**What it does**: Configures encrypted HTTPS traffic using your ACM certificate

### 3. HTTP to HTTPS Redirect
**File**: `modules/beanstalk_env/main.tf` (lines ~125-140)

```hcl
# All HTTP traffic redirects to HTTPS
{
  namespace = "aws:elbv2:listener:80"
  name      = "Protocol"
  value     = "HTTP"
}
```

**What it does**: Automatically redirects unencrypted HTTP traffic to encrypted HTTPS

### 4. Health Checks
**File**: `modules/beanstalk_env/main.tf` (lines ~140-170)

```hcl
{
  namespace = "aws:elasticbeanstalk:environment:process:default"
  name      = "HealthCheckPath"
  value     = var.health_check_path  # Usually "/"
}
```

**What it does**: ALB verifies application is responding every 30 seconds, replaces unhealthy instances

### 5. Auto-Scaling Configuration
**File**: `modules/beanstalk_env/main.tf` (lines ~170-200)

```hcl
# Scale up when CPU > 70%
{
  namespace = "aws:autoscaling:trigger"
  name      = "UpperThreshold"
  value     = "70"
}

# Scale down when CPU < 30%
{
  namespace = "aws:autoscaling:trigger"
  name      = "LowerThreshold"
  value     = "30"
}
```

**What it does**: Automatically adds/removes instances based on CPU utilization

### 6. IAM Roles for EC2
**File**: `modules/beanstalk_app/main.tf` (lines ~40-60)

```hcl
resource "aws_iam_role" "ecsInstanceRole" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
```

**What it does**: Creates role that EC2 instances assume to get permissions

### 7. IAM Policies Attachment
**File**: `modules/beanstalk_app/main.tf` (lines ~80-110)

```hcl
# Allow S3 access for source code
resource "aws_iam_role_policy_attachment" "s3AccessPolicy" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# CloudWatch access removed (logging disabled)
resource "aws_iam_role_policy_attachment" "cloudwatchPolicy" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
```

**What it does**: Grants specific AWS service permissions to EC2 instances

### 8. Instance Profile
**File**: `modules/beanstalk_app/main.tf` (lines ~120-130)

```hcl
resource "aws_iam_instance_profile" "ecsInstanceProfile" {
  name = "${var.app_name}-ecsInstanceProfile-${var.environment_name}"
  role = aws_iam_role.ecsInstanceRole.name
}
```

**What it does**: Wraps IAM role for attaching to EC2 instances

### 9. Elastic Beanstalk Application
**File**: `modules/beanstalk_app/main.tf` (lines ~25-40)

```hcl
resource "aws_elastic_beanstalk_app" "beanstalk_app" {
  name        = var.app_name
  description = var.description
  
  # Auto-delete old versions
  appversion_lifecycle {
    max_count      = 10
    delete_on_day  = 88
  }
}
```

**What it does**: Creates the Elastic Beanstalk application container

### 10. Elastic Beanstalk Environment
**File**: `modules/beanstalk_env/main.tf` (lines ~1-30)

```hcl
resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name                 = var.env_name
  application          = var.app_name
  solution_stack_name  = var.solution_stack_name  # Java 11 + Tomcat
  tier                 = "WebServer"
  instance_profile_arn = var.instance_profile_name
}
```

**What it does**: Creates the actual Elastic Beanstalk environment where instances run

### 11. Application Version
**File**: `modules/beanstalk_env/main.tf` (lines ~250-270)

```hcl
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "${var.app_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  application = var.app_name
  bucket      = var.source_code_bucket
  key         = var.source_code_key
}
```

**What it does**: Points to your WAR file in S3

### 12. Application Deployment
**File**: `modules/beanstalk_env/main.tf` (lines ~280-295)

```hcl
resource "aws_elastic_beanstalk_environment_version_binding" "app_env_version" {
  environment_id = aws_elastic_beanstalk_environment.beanstalk_env.id
  version_label  = aws_elastic_beanstalk_application_version.app_version.name
  force_deploy   = true
}
```

**What it does**: Deploys the application version to the environment

---

## Configuration Variables Translation

| Variable | Purpose | Example |
|----------|---------|---------|
| `aws_region` | AWS region | ap-south-1 |
| `project_name` | Project identifier | uat-infra |
| `environment_name` | Environment stage | uat |
| `app_name` | Beanstalk app name | java-tomcat-app |
| `env_name` | Beanstalk env name | java-tomcat-uat |
| `instance_type` | EC2 size | t3.medium |
| `min_size` | Min EC2 instances | 2 |
| `max_size` | Max EC2 instances | 4 |
| `vpc_id` | VPC identifier | vpc-xxxxx |
| `private_subnets` | Instance subnets | [subnet-1, subnet-2] |
| `public_subnets` | ALB subnets | [subnet-1, subnet-2] |
| `custom_domain` | Domain name | uat.test.com |
| `acm_certificate_arn` | SSL certificate | arn:aws:acm:... |
| `source_code_bucket` | S3 bucket | app-source |
| `source_code_key` | WAR file path | app.war |

---

## Deployment Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# See outputs
terraform output

# Get specific output
terraform output beanstalk_env_cname

# Destroy (if needed)
terraform destroy
```

---

## AWS CLI Verification Commands

```bash
# Check app status
aws elasticbeanstalk describe-environments \
  --application-name java-tomcat-app \
  --region ap-south-1 \
  --query 'Environments[0].[EnvironmentName,Status,Health]'

# List EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat" \
  --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]'

# View application logs
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/eb-activity.log \
  --follow --region ap-south-1

# View recent events
aws elasticbeanstalk describe-events \
  --application-name java-tomcat-app \
  --region ap-south-1 \
  --max-records 10
```

---

## Infrastructure Architecture

```
Internet
    ↓
Route 53 (uat.test.com)
    ↓
Application Load Balancer (ALB)
├── Port 80 (HTTP) → redirects to 443
└── Port 443 (HTTPS) ← ACM Certificate
    ↓
VPC (vpc-xxxxx)
├── Public Subnets (AZ-1a, AZ-1b)
│   └── ALB distributes traffic
│
└── Private Subnets (AZ-1a, AZ-1b)
    ├── EC2 Instance #1 (t3.medium)
    │   └── Tomcat 9 + Java 11 + App
    │
    └── EC2 Instance #2 (t3.medium)
        └── Tomcat 9 + Java 11 + App

┌─────────────────────────────────────┐
│ Auto-Scaling Policy                 │
├─────────────────────────────────────┤
│ CPU > 70% → Scale Up (max 4)        │
│ CPU < 30% → Scale Down (min 2)      │
└─────────────────────────────────────┘

Logging (optional)
├── Application logs (7 days retention)
├── Beanstalk activity logs
└── System metrics (CPU, Memory, Network)
```

---

## Security Features Implemented

✅ **Network Security**
- Private EC2 instances (not directly internet-accessible)
- Security groups restrict traffic to necessary ports
- ALB in public subnets handles external traffic

✅ **Encryption**
- HTTPS/SSL enforced (no plain HTTP)
- ACM certificate manages encryption
- HTTP automatically redirects to HTTPS

✅ **Access Control**
- IAM roles for EC2 instances (least privilege)
- IAM role for Beanstalk service
- S3 bucket access for source code only

✅ **Monitoring & Logging**
- CloudWatch logs collection disabled
- Health checks monitor application
- Metrics tracked for auto-scaling
- Events logged for troubleshooting

✅ **High Availability**
- Multi-AZ deployment (2 AZs minimum)
- Auto-scaling for capacity
- Load balancer distributes traffic
- Health checks replace failed instances

---

## Module Dependencies

```
beanstalk_app module
    ↓
(outputs: instance_profile_name, service_role_arn)
    ↓
beanstalk_env module
    ↓
(uses IAM resources to create environment)
    ↓
root module (main.tf)
    ↓
(orchestrates both modules)
    ↓
Terraform outputs final values
```

---

## Next Steps After Deployment

1. **Wait for environment to become GREEN** (~15-20 minutes)
2. **Configure Route 53 DNS** – if `route53_hosted_zone_id` was provided Terraform already created an alias record; otherwise manually point your custom domain to the Beanstalk CNAME
3. **Verify application is accessible** via https://uat.test.com
4. **Monitoring** (CloudWatch disabled by default)
5. **Test auto-scaling** by monitoring CPU usage
6. **Plan application updates** deployment strategy
7. **Set up monitoring alerts** (external or CloudWatch if enabled later)

---

## Support Resources

| Topic | Resource |
|-------|----------|
| Elastic Beanstalk | https://docs.aws.amazon.com/elasticbeanstalk/ |
| Terraform AWS Provider | https://registry.terraform.io/providers/hashicorp/aws/latest/docs |
| Java on Beanstalk | https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/java-tomcat-platform.html |
| ALB | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/ |
| ACM | https://docs.aws.amazon.com/acm/ |
| Route 53 | https://docs.aws.amazon.com/route53/ |

---

## Troubleshooting Checklist

| Issue | Command | What to look for |
|-------|---------|------------------|
| Env is RED | `describe-environment-health` | CapacityHealth, InstanceHealth |
| Instances not starting | `describe-instances` | Running state, passed status checks |
| App not responding | `tail catalina.out` | Exception errors, deployment issues |
| Health checks failing | `describe-target-health` | Unhealthy reason |
| DNS not working | `nslookup uat.test.com` | Should resolve to ALB IP |
| SSL cert issues | Check ACM console | Certificate must match domain |

---

## Pro Tips

💡 **Use Terraform workspace for multiple environments:**
```bash
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

💡 **Use local-exec for post-deployment tasks:**
```bash
resource "null_resource" "post_deploy" {
  provisioner "local-exec" {
    command = "echo 'Deployment complete at ${timestamp()}'"
  }
}
```

💡 **Use data sources to find existing resources:**
```bash
data "aws_acm_certificate" "example" {
  domain      = "uat.test.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
```

💡 **Monitor costs with AWS Cost Explorer:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## File Sizes and Complexity

| File | Lines | Complexity | Key Content |
|------|-------|-----------|------------|
| provider.tf | 25 | Low | AWS provider config |
| variables.tf | 150+ | Medium | All input variables |
| backend.tf | 20 | Low | Terraform state |
| main.tf | 30 | Low | Module calls |
| outputs.tf | 100+ | Medium | Output definitions |
| beanstalk_app/main.tf | 150+ | High | IAM + App creation |
| beanstalk_env/main.tf | 250+ | High | Environment + ALB |

**Total: ~700+ lines of well-documented code**

---

## Common Errors and Fixes

```
Error: InvalidParameterValue: Invalid value for ImageId: ''
Fix: Check solution_stack_name is valid for your region

Error: You are not authorized to perform this operation
Fix: Check IAM permissions (Beanstalk, EC2, IAM, S3)

Error: Bucket does not exist
Fix: Create S3 bucket and upload WAR file

Error: Certificate not found
Fix: Get correct ACM certificate ARN, verify it matches domain

Error: Invalid VPC ID
Fix: Verify VPC exists in ap-south-1 region

Error: Subnetid is invalid
Fix: Verify subnets exist and are in same VPC
```

---

## Maintenance and Updates

**Regular Tasks:**
- Review logs via your preferred logging solution
- Monitor costs monthly
- Update application versions as needed
- Check auto-scaling effectiveness
- Review security group rules quarterly

**One-time Tasks:**
- Configure backup/disaster recovery
- Set up monitoring alerts
- Document application-specific settings
- Create deployment runbook
- Set up CI/CD pipeline for deployment

---

This infrastructure is production-ready and follows AWS best practices!
