# Troubleshooting and Debugging Guide

## Pre-Deployment Validation

Before deploying, ensure all prerequisites are in place:

```bash
#!/bin/bash
# Pre-deployment validation script

echo "=== Checking AWS CLI ==="
aws --version
aws sts get-caller-identity

echo "=== Checking Terraform ==="
terraform --version
terraform validate

echo "=== Checking VPC ==="
VPC_ID="vpc-xxxxxxxxxxxxxxx"
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region ap-south-1

echo "=== Checking Subnets ==="
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region ap-south-1 \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,MapPublicIpOnLaunch]'

echo "=== Checking ACM Certificate ==="
aws acm list-certificates --region ap-south-1

echo "=== Checking S3 Bucket ==="
aws s3 ls s3://my-app-source-bucket/

echo "=== All checks complete ==="
```

---

## Common Pre-Deployment Issues

### Issue 1: AWS Credentials Not Configured

**Error:**
```
Error: Unable to locate credentials
```

**Solution:**
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-south-1"

# Verify configuration
aws sts get-caller-identity
```

### Issue 2: Invalid VPC or Subnet IDs

**Error:**
```
Error: InvalidParameterValue: Invalid id: "vpc-xxxxx" InvalidVpcID.NotFound
```

**Solution:**
```bash
# List available VPCs
aws ec2 describe-vpcs \
  --region ap-south-1 \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# List subnets in VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --region ap-south-1 \
  --output table

# Update terraform.tfvars with correct IDs
```

### Issue 3: Solution Stack Not Found

**Error:**
```
Error: InvalidParameterValue: No Platform named 'xyz' found
```

**Solution:**
```bash
# List available solution stacks for your region
aws elasticbeanstalk list-available-solution-stacks \
  --region ap-south-1 \
  --query 'SolutionStacks[]' | grep -i java | grep -i tomcat

# Use the exact name from output in solution_stack_name
```

### Issue 4: S3 Bucket and WAR File Not Found

**Error:**
```
Error: ValidationError (Service: beanstalk): NoSuchBucket
```

**Solution:**
```bash
# Create S3 bucket if missing
aws s3 mb s3://my-app-source-bucket --region ap-south-1

# Upload WAR file
aws s3 cp target/app.war s3://my-app-source-bucket/app.war

# Verify upload
aws s3 ls s3://my-app-source-bucket/ --recursive

# Update source_code_bucket and source_code_key in terraform.tfvars
```

### Issue 5: ACM Certificate Not Found

**Error:**
```
Error: ValidationError: The certificate 'arn:aws:acm:...' does not exist
```

**Solution:**
```bash
# List available certificates
aws acm list-certificates \
  --region ap-south-1 \
  --query 'CertificateSummaryList[*].[CertificateArn,DomainName,Status]' \
  --output table

# Certificate must be in same region (ap-south-1)
# Use correct ARN in acm_certificate_arn variable
```

---

## Post-Deployment Issues

### Issue 1: Environment Status is RED

**Symptoms:**
- Beanstalk environment shows RED health status
- Instances appear unhealthy
- Application not responding

**Diagnosis:**
```bash
# Get detailed health information
aws elasticbeanstalk describe-environment-health \
  --environment-name java-tomcat-uat \
  --attribute-name All \
  --region ap-south-1 \
  --output json | jq '.'

# Check recent events
aws elasticbeanstalk describe-events \
  --application-name java-tomcat-app \
  --environment-name java-tomcat-uat \
  --max-records 20 \
  --region ap-south-1 \
  --output json | jq '.Events[].Message'

# View Beanstalk activity log
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/eb-activity.log \
  --follow --region ap-south-1

# View Tomcat logs
aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/tomcat/catalina.out \
  --follow --region ap-south-1
```

**Common Causes and Solutions:**

1. **Invalid WAR file**
   ```bash
   # Check WAR file is valid
   jar tf /path/to/app.war | head
   
   # Re-upload if corrupted
   aws s3 cp target/app.war s3://my-app-source-bucket/app.war --sse AES256
   ```

2. **Application crashes on startup**
   ```bash
   # Check application logs
   aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/tomcat/catalina.out \
     --follow --region ap-south-1
   
   # Look for:
   # - ClassNotFoundException
   # - NullPointerException
   # - OutOfMemoryError
   # - Port binding errors
   ```

3. **Out of memory**
   ```bash
   # Check current JVM settings
   aws elasticbeanstalk describe-configuration-settings \
     --application-name java-tomcat-app \
     --environment-name java-tomcat-uat \
     --region ap-south-1 \
     --query 'ConfigurationSettings[0].OptionSettings[?contains(Value, `Xmx`)]'
   
   # Increase heap size in terraform
   # Update JAVA_OPTS in beanstalk_env/main.tf
   ```

4. **Port already in use**
   ```bash
   # Beanstalk uses port 80 on instances
   # Make sure nothing else is running on port 80
   
   # SSH to instance and check
   aws ssm start-session --target i-xxxxx
   netstat -tulpn | grep LISTEN
   ```

### Issue 2: Instances Keep Restarting

**Symptoms:**
- Instance health keeps toggling between healthy and unhealthy
- Auto-scaling terminates and recreates instances repeatedly
- Event logs show constant restarts

**Diagnosis:**
```bash
# Check instance logs via Systems Manager
aws ssm start-session --target i-xxxxx

# Inside session:
tail -f /var/log/eb-activity.log
tail -f /var/log/tomcat/catalina.out
tail -f /var/log/messages

# Check system resources
free -h
df -h
top

# Check if port is binding
netstat -tulpn | grep :80
```

**Solutions:**

1. **Invalid application configuration**
   ```bash
   # Check web.xml and other configs
   jar tf target/app.war | grep -i web.xml
   
   # Use valid configuration
   ```

2. **Memory issues**
   ```bash
   # Use larger instance type
   # Edit variables.tf: instance_type = "t3.large"
   
   # Or increase Tomcat memory
   # In beanstalk_env/main.tf, update:
   {
     namespace = "aws:elasticbeanstalk:application:environment"
     name      = "JAVA_OPTS"
     value     = "-Xmx1024m -Xms512m"  # Increase these
   }
   ```

3. **Health check path doesn't exist**
   ```bash
   # Change health check path to your application endpoint
   # In terraform.tfvars:
   health_check_path = "/health"  # or your actual endpoint
   
   # Or use root path if "/" exists
   ```

### Issue 3: Health Checks Failing

**Symptoms:**
- Target health shows "unhealthy"
- ALB reports no healthy targets
- 502/503 errors when accessing application

**Diagnosis:**
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/... \
  --region ap-south-1

# SSH to instance and test health check path
aws ssm start-session --target i-xxxxx

# Inside session:
curl -v localhost:80/
curl -v localhost:80/health

# Check if Tomcat is running
ps aux | grep tomcat
netstat -tulpn | grep :80

# Check Tomcat logs
tail -f /var/log/tomcat/catalina.out
```

**Solutions:**

1. **Application not listening on port 80**
   ```bash
   # Verify instance security group allows port 80
   aws ec2 describe-security-groups \
     --filters "Name=group-id,Values=sg-xxxxx" \
     --region ap-south-1
   
   # Should show inbound rule for port 80 from ALB security group
   ```

2. **Application doesn't respond to health check path**
   ```bash
   # Change health check path in terraform:
   health_check_path = "/"  # Root path
   
   # Or update application to respond to health check endpoint
   ```

3. **Health check timeout too short**
   ```bash
   # Increase timeout
   # In terraform.tfvars:
   health_check_timeout = 10  # Increased from 5
   ```

### Issue 4: Application Returns 502/503 Errors

**Symptoms:**
- Browser shows "Bad Gateway" (502) or "Service Unavailable" (503)
- ALB is responding but forwarding to unhealthy instances
- Intermittent errors

**Diagnosis:**
```bash
# Check ALB logs (if enabled)
aws s3 ls s3://elasticbeanstalk-logs-xxxxx/ --recursive

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-south-1:... \
  --region ap-south-1

# SSH to instance and check service
aws ssm start-session --target i-xxxxx

# Inside session:
curl -v localhost:80/

# Check Tomcat process
ps aux | grep tomcat
netstat -tulpn | grep :80
```

**Solutions:**

1. **Tomcat crashed or not running**
   ```bash
   # Restart Tomcat via Beanstalk
   aws elasticbeanstalk restart-app-server \
     --environment-name java-tomcat-uat \
     --region ap-south-1
   
   # Or manually (if SSH'd into instance):
   sudo /opt/elasticbeanstalk/tasks/bundlelogs.d/tomcat.sh stop
   sudo /opt/elasticbeanstalk/tasks/bundlelogs.d/tomcat.sh start
   ```

2. **Application throwing exceptions**
   ```bash
   # Check application logs
   aws logs tail /aws/elasticbeanstalk/java-tomcat-uat/var/log/tomcat/catalina.out \
     --follow --region ap-south-1
   
   # Look for stack traces and fix application code
   ```

3. **Database or external service connection issues**
   ```bash
   # Check if RDS/other services are reachable
   # Add debugging to application logs
   # Verify IAM role has permissions to connect
   ```

### Issue 5: SSH Access Problems to EC2

**Symptoms:**
- Cannot SSH to instances
- Session Manager fails
- Permission denied errors

**Solution:**

```bash
# Verify instance is running
aws ec2 describe-instances \
  --filters "Name=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat" \
  --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,IamInstanceProfile.Arn]'

# Verify instance profile and IAM role
aws iam get-instance-profile \
  --instance-profile-name java-tomcat-app-ecsInstanceProfile-uat

# Check if SSM agent is running (EC2 Systems Manager)
aws ssm describe-instance-information \
  --filters "Key=tag:aws:elasticbeanstalk:environment-name,Values=java-tomcat-uat" \
  --region ap-south-1

# Use Systems Manager Session Manager to connect
aws ssm start-session \
  --target i-xxxxxxxxxxxxx \
  --region ap-south-1

# If still having issues, check IAM policy for Systems Manager access
```

---

## DNS and Domain Configuration Issues

### Issue 1: Domain Not Resolving

If you supplied `route53_hosted_zone_id` the record should have been
created automatically; check with `terraform output route53_alias_record_name`.
Otherwise follow the manual diagnostic steps below.

**Symptoms:**
- `nslookup uat.test.com` returns no results
- Browser "can't find server"
- DNS timeout errors

**Diagnosis:**
```bash
# Check if Route 53 record exists
HOSTED_ZONE_ID="Z123456789ABC"
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query 'ResourceRecordSets[?Name==`uat.test.com.`]' \
  --region ap-south-1

# Test DNS resolution
nslookup uat.test.com
dig uat.test.com
host uat.test.com

# Check nameservers
dig uat.test.com +trace
```

**Solutions:**

1. **Record doesn't exist**
   ```bash
   # Create CNAME record pointing to Beanstalk CNAME
   BEANSTALK_CNAME=$(terraform output -raw beanstalk_env_cname)
   
   aws route53 change-resource-record-sets \
     --hosted-zone-id $HOSTED_ZONE_ID \
     --change-batch "{
       \"Changes\": [{
         \"Action\": \"CREATE\",
         \"ResourceRecordSet\": {
           \"Name\": \"uat.test.com\",
           \"Type\": \"CNAME\",
           \"TTL\": 300,
           \"ResourceRecords\": [{\"Value\": \"$BEANSTALK_CNAME\"}]
         }
       }]
     }" \
     --region ap-south-1
   ```

2. **DNS propagation delay**
   ```bash
   # Wait up to 5 minutes for global DNS propagation
   # Run periodic checks
   for i in {1..30}; do
     echo "Attempt $i:"
     nslookup uat.test.com || true
     sleep 10
   done
   ```

3. **Wrong hosted zone**
   ```bash
   # Verify hosted zone matches your domain
   aws route53 list-hosted-zones-by-name \
     --query 'HostedZones[?Name==`test.com.`]'
   
   # Use correct hosted zone ID
   ```

### Issue 2: SSL Certificate Mismatch

**Symptoms:**
- "Certificate doesn't match domain" warning
- "Subject Alternative Name missing" error
- Browser warning about self-signed certificate

**Solutions:**

```bash
# Verify certificate details
CERT_ARN="arn:aws:acm:ap-south-1:..."
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region ap-south-1 \
  --query 'Certificate.[DomainName,SubjectAlternativeNames,Status]'

# Certificate must match your domain or include it in SAN
# If mismatch, create new certificate in ACM for your domain

# Request new certificate if needed
aws acm request-certificate \
  --domain-name uat.test.com \
  --validation-method DNS \
  --region ap-south-1

# Update terraform variable with new certificate ARN
```

---

## Performance and Scaling Issues

### Issue 1: Application Running Slowly

**Diagnosis:**
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-south-1

# Check memory usage
aws ssm start-session --target i-xxxxx
# Inside session:
free -h
ps aux --sort-%mem | head
```

**Solutions:**

1. **Upgrade instance type**
   ```hcl
   # In terraform.tfvars:
   instance_type = "t3.large"  # From t3.medium
   
   # Apply changes
   terraform apply
   ```

2. **Increase JVM heap size**
   ```hcl
   # In beanstalk_env/main.tf, update JAVA_OPTS:
   {
     namespace = "aws:elasticbeanstalk:application:environment"
     name      = "JAVA_OPTS"
     value     = "-Xmx2048m -Xms1024m"  # Increased from 512m/256m
   }
   ```

### Issue 2: Auto-Scaling Not Working

**Diagnosis:**
```bash
# Check Auto Scaling Group
ASG_NAME=$(aws elasticbeanstalk describe-environments \
  --environment-name java-tomcat-uat \
  --region ap-south-1 \
  --query 'Environments[0].AutoScalingGroups[0].Name' \
  --output text)

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --region ap-south-1

# Check scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name $ASG_NAME \
  --region ap-south-1

# Check if CPU metric is being tracked
# (CloudWatch list-metrics command omitted)```

**Solutions:**

1. **Adjust scaling thresholds**
   ```hcl
   # In beanstalk_env/main.tf:
   {
     namespace = "aws:autoscaling:trigger"
     name      = "UpperThreshold"
     value     = "60"  # Scale up at 60% instead of 70%
   },
   {
     namespace = "aws:autoscaling:trigger"
     name      = "LowerThreshold"
     value     = "20"  # Scale down at 20% instead of 30%
   }
   ```

2. **Verify max capacity is sufficient**
   ```bash
   # Check current instances vs max
   aws autoscaling describe-auto-scaling-groups \
     --auto-scaling-group-names $ASG_NAME \
     --region ap-south-1 \
     --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity,InstanceCount]'
   ```

---

## Terraform-Specific Issues

### Issue 1: State File Lock

**Error:**
```
Error: error acquiring the state lock: 
ConditionalCheckFailedException: The conditional request failed
```

**Solution:**
```bash
# List lock items
aws dynamodb scan \
  --table-name terraform-state-lock \
  --region ap-south-1

# Force unlock (use with caution!)
terraform force-unlock <LOCK-ID>

# Or manually delete from DynamoDB (last resort)
```

### Issue 2: Resource Not Found During Destroy

**Error:**
```
Error: error reading EC2 Instance (i-xxxxx): InvalidInstanceID.NotFound
```

**Solution:**
```bash
# Remove from state (if resource was manually deleted)
terraform state rm 'aws_instance.example'

# Then proceed with destroy
terraform destroy

# Or refresh state
terraform refresh
```

### Issue 3: Configuration Drift

**Problem:**
Manual changes to AWS console that differ from Terraform

**Solution:**
```bash
# Detect drift
terraform plan

# Refresh state from AWS
terraform refresh

# Reapply to match state
terraform apply
```

---

## Monitoring and Alerting Setup

```bash
# CloudWatch alarm creation steps omitted (monitoring disabled)
# Alarm creation for unhealthy targets omitted (monitoring disabled)```

---

## Recovery Procedures

### Complete Environment Recreation

If environment becomes unstable:

```bash
# 1. Backup application version
aws elasticbeanstalk describe-application-versions \
  --application-name java-tomcat-app \
  --region ap-south-1

# 2. Terminate environment
terraform destroy -target=module.beanstalk_env

# Wait 5-10 minutes

# 3. Recreate environment
terraform apply -target=module.beanstalk_env

# 4. Verify
aws elasticbeanstalk describe-environments \
  --environment-name java-tomcat-uat \
  --region ap-south-1
```

### Rollback to Previous Application Version

```bash
# List application versions
aws elasticbeanstalk describe-application-versions \
  --application-name java-tomcat-app \
  --region ap-south-1

# Deploy specific version
aws elasticbeanstalk update-environment \
  --environment-name java-tomcat-uat \
  --version-label app-v1.0.0 \
  --region ap-south-1

# Monitor deployment
aws elasticbeanstalk describe-events \
  --application-name java-tomcat-app \
  --max-records 10 \
  --region ap-south-1
```

---

## Emergency Contacts and Resources

- **AWS Support**: https://console.aws.amazon.com/support/
- **AWS Status Page**: https://health.aws.amazon.com/
- **Beanstalk Documentation**: https://docs.aws.amazon.com/elasticbeanstalk/
- **Terraform Documentation**: https://www.terraform.io/docs/

---

This guide covers most common issues and their solutions. For issues not covered, check AWS documentation or contact AWS support.
