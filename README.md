AP-South-1

vpc-id : vpc-089a69f9765b6bd52
subnet id : subnet-0108669173b478aa0 , subnet-04ea9ba32d0776e2d
acm: 


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




Since you created a VPC module, we will structure it using enterprise best practices.

📁 Recommended Structure
terraform-project/
│
├── main.tf
├── variables.tf
├── outputs.tf
│
└── modules/
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf

🔹 ROOT LEVEL (Environment Layer)

This layer calls the module.
It should NOT contain resource definitions for VPC directly.

1️⃣ Root main.tf

👉 Purpose: Call the VPC module

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

What happens here?

Defines AWS provider

Passes variables to module

Acts as orchestration layer

This file should be very clean.

2️⃣ Root variables.tf

👉 Purpose: Define input variables for environment

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}


These are environment-level inputs.

Example terraform.tfvars:

region = "ap-south-1"
vpc_name = "prod-vpc"
vpc_cidr = "10.0.0.0/16"

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

availability_zones = ["ap-south-1a", "ap-south-1b"]

3️⃣ Root outputs.tf

👉 Purpose: Expose module outputs to outside world

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}


This allows:

Other root modules to consume

CI/CD pipeline visibility

Remote state sharing

🔹 MODULE LEVEL (Reusable Infrastructure Layer)

This is where actual resources are created.

4️⃣ Module main.tf

👉 Purpose: Define actual AWS resources

Example:

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.vpc_name}-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.vpc_name}-private-${count.index}"
  }
}


This file:

Contains actual infrastructure resources

Uses only module variables

No hardcoding

5️⃣ Module variables.tf

👉 Purpose: Define variables expected by module

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}


This defines the module contract.

Think of it as:

“If you want to use this VPC module, you must provide these inputs.”

6️⃣ Module outputs.tf

👉 Purpose: Expose values from inside module

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}


These outputs are consumed by:

Root outputs

Other modules (EKS, ECS, RDS, etc.)

🔥 Very Important Concept
Root = Orchestration Layer
Module = Reusable Infrastructure Logic
🎯 Enterprise Best Practice Flow
Root Layer
   ↓
Calls Module
   ↓
Module Creates Resources
   ↓
Module Outputs
   ↓
Root Exposes Outputs

🧠 When You Add More Modules

Example:

modules/
  vpc/
  ecs/
  rds/
  alb/


Root main.tf becomes:

module "vpc" { ... }

module "ecs" {
  source = "./modules/ecs"
  vpc_id = module.vpc.vpc_id
}


That’s how you chain modules.

⚠ Common Mistakes You Must Avoid

❌ Creating resources in root
❌ Hardcoding CIDR inside module
❌ Not defining outputs
❌ Mixing dev/prod configs inside module

📌 Simple Summary
File	Purpose
Root main.tf	Calls module
Root variables.tf	Defines environment inputs
Root outputs.tf	Exposes module outputs
Module main.tf	Creates AWS resources
Module variables.tf	Defines module input contract
Module outputs.tf	Returns created resource values

If you want, I can now:

Build a production-ready enterprise VPC module

Or show how to integrate it with ECS/EKS

Or explain backend.tf and remote state structure properly**

so, in root
main.tf contains main configurations of  a vpc this calls the main.tf in vpc module 
variable.tf contains variables that calls the variables.tf in vpc module
correct..?

Not exactly. Your understanding is close — but slightly incorrect architecturally.

Let me correct it precisely.

❌ What You Said (Small Mistake)

root main.tf contains main configurations of VPC and calls module main.tf
root variables.tf calls module variables.tf

This wording is not technically accurate.

✅ Correct Understanding

Terraform does NOT “call main.tf” or “call variables.tf” directly.

Terraform calls:

module block


The module block loads the entire module folder — not individual files.

Inside a module folder:

main.tf

variables.tf

outputs.tf

All are automatically read together.

Terraform treats the module directory as a single unit.

🔎 What Actually Happens Internally

When you write in root:

module "vpc" {
  source = "./modules/vpc"

  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
}


Terraform does this:

Loads entire ./modules/vpc directory

Reads all .tf files inside it

Matches input arguments with variables defined in module variables.tf

Creates resources defined in module main.tf

Makes outputs available from module outputs.tf

🔥 So The Correct Concept Is
Root main.tf

Does NOT contain VPC resources

Only defines provider + module block

Passes input variables to module

It orchestrates.

Root variables.tf

Defines variables for the root module (environment layer)

These values are passed into the module block

It does NOT “call” module variables file

Instead:

Root variable → passed into → Module variable

Example:

Root variable "vpc_name"
        ↓
module block argument
        ↓
Module variable "vpc_name"

🎯 Very Important Concept

Terraform works like function calling in programming.

Think of module like a function:

function vpc(vpc_name, vpc_cidr) {
   create aws_vpc
   return vpc_id
}


Root calls:

vpc("prod-vpc", "10.0.0.0/16")

🧠 Clean Mental Model
Layer	Role
Root	Environment orchestrator
Module	Infrastructure implementation
variables.tf	Input definition
main.tf	Resource creation
outputs.tf	Return values
⚠ Most Important Correction

Root does NOT call:

module main.tf

module variables.tf

It calls:

the module folder


Terraform loads everything inside automatically.

💎 One-Line Correct Statement

Root main.tf calls the module block, which loads the entire VPC module directory; root variables.tf defines inputs that are passed into module variables.
