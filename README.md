**TARGET ARCHITECTURE**

Jenkins
   ↓
Build ROOT.war
   ↓
Upload WAR to S3
   ↓
Terraform Apply (Blue Environment)
   ↓
Health Check
   ↓
Auto CNAME Swap
   ↓
CloudFront Origin Update
   ↓
Invalidate Cache
   ↓
Traffic Shifted


**Final Production Flow (Very Clear)**

GitHub Push
   ↓
Jenkins Build
   ↓
WAR Created
   ↓
Upload to S3
   ↓
Terraform Plan
   ↓
Manual Approval
   ↓
Terraform Apply (Green)
   ↓
Wait
   ↓
Smoke Test (Green)
   ↓
If Success → CNAME Swap
   ↓
CloudFront Invalidation
   ↓
Traffic Shifted


What This Pipeline Covers
✔ GitHub integration
✔ 6 application stages
✔ SonarQube analysis
✔ Quality gate enforcement
✔ Artifact versioning
✔ Separate Terraform repo
✔ Manual approval before infra change
✔ Blue/Green deployment
✔ 5-minute smoke test
✔ Automatic rollback
✔ CloudFront invalidation
✔ Email notification
🔥 Enterprise Behavior Summary
If Sonar fails → pipeline stops
If Quality Gate fails → pipeline stops
If Terraform fails → rollback
If Smoke test fails → rollback
If Swap fails → rollback
If everything succeeds → email success


**COMPLETE MODULAR TERRAFORM STRUCTURE**

terraform/
│
├── environments/
│   ├── uat/
│   │   ├── backend.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── main.tf
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── backend.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── main.tf
│       └── outputs.tf
│
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security-groups/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── beanstalk-app/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── beanstalk-environment/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloudfront/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── route53/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf


**Why This Structure?**

modules/ = reusable building blocks

environments/uat = UAT configuration

environments/prod = Production configuration

Each environment has its own backend and tfvars

Blue/Green handled at environment level


**AUTO SWAP SCRIPT (Jenkins)**
After terraform apply:

        ACTIVE_ENV=$(aws elasticbeanstalk describe-environments \
        --application-name monolith-prod \
        --query "Environments[?Status=='Ready'].EnvironmentName" \
        --output text)

        if [[ "$ACTIVE_ENV" == *"blue"* ]]; then
        TARGET="green"
        else
        TARGET="blue"
        fi

        aws elasticbeanstalk swap-environment-cnames \
        --source-environment-name monolith-prod-$TARGET \
        --destination-environment-name monolith-prod-$ACTIVE_ENV


**PRODUCTION-GRADE JENKINS TERRAFORM SCRIPT**
        cd terraform/

        terraform init

        terraform plan \
        -var="build_number=${BUILD_NUMBER}" \
        -var="environment_color=green" \
        -out=tfplan

        terraform apply -auto-approve 

        
**Where to save and how to execute swap-environment-cnames**

Where to put health validation + smoke test

Add 5-minute smoke test

Create production VPC + Security Group modules

Attach VPC + SG to Beanstalk env properly


**HOW TO EXECUTE IN JENKINS**

Inside Jenkins pipeline (after terraform apply):

chmod +x deployment/swap_and_validate.sh
./deployment/swap_and_validate.sh green


**ROLLBACK**

Rollback = run same script with opposite color:

./deployment/swap_and_validate.sh blue

Rollback time: ~30 seconds.

**Production Security Checklist**
Component	Production Ready?
VPC	✅
Public/Private subnets	✅
NAT	✅
Route tables	✅
SG separation (ALB/EC2)	✅
Beanstalk autoscaling	✅
Immutable deployment	✅
Enhanced health	✅
CloudFront HTTPS	✅
Route53 alias	✅
ACM enforced	✅
Logging	✅
