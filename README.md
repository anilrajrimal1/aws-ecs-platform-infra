# FormFlow Platform Infrastructure

Production-grade AWS infrastructure for a multi-service web application platform. Built with Terraform and Terragrunt to enforce DRY configuration, environment separation, and remote state management.

## Overview

This repository provisions the complete AWS infrastructure for **FormFlow**, a data collection and form management platform composed of a Django web application, a FastAPI async API layer, an open-source form rendering service, and Celery-based background workers.

The architecture targets reliable operation for moderate traffic workloads and is designed to scale horizontally at the ECS service level.

## Architecture

```
Internet
   |
CloudFront (app.anilrajrimal.com.np | forms.anilrajrimal.com.np)
   |                 |
  S3 (static)      ALB (HTTPS/443)
                    |
       --------------------------------
       |            |                |
    ECS Web     ECS FastAPI    ECS Forms Service
    (Django)    (Async API)    (Form Collection)
       |            |                |
       --------- ECS Workers --------
          (Celery Beat, Worker, Report, Submission)
                    |
    ----------------------------------------
    |           |           |          |
   RDS        Redis       Redis       EFS
(Aurora    (Sessions)   (Cache)   (Shared mounts)
Serverless)
```

**Key components:**

- **VPC** with public and private subnets across multiple availability zones, NAT Gateway, and AWS Cloud Map for internal service discovery
- **ALB** with path and host-based routing to four distinct services
- **ECS Fargate** for all application containers, grouped into persistent (non-purgeable) and ephemeral (purgeable) tiers
- **Aurora PostgreSQL 15 Serverless v2** scaling between 24 and 64 ACUs
- **Redis 7.0** with separate clusters for sessions and application caching
- **CloudFront** distributions with S3 origins for static assets and ALB origins for dynamic content
- **ECR** with KMS encryption and image scanning on push
- **EFS** for shared configuration files mounted read-only into select containers
- **Secrets Manager** for application credentials surfaced as ECS task secrets
- **EC2 bastion** with scoped IAM permissions for deployment and operational access

For a deeper breakdown see [architecture.md](architecture.md) and [decisions.md](decisions.md).

## Folder Structure

```
.
├── deployments/
│   ├── root.hcl                    # Root config: provider generation, remote state, default tags
│   ├── _envcommon/                 # Per-component defaults shared across all environments
│   │   ├── alb.hcl
│   │   ├── cloudfront.hcl
│   │   ├── ec2.hcl
│   │   ├── ecr.hcl
│   │   ├── ecs.hcl
│   │   ├── efs.hcl
│   │   ├── rds.hcl
│   │   ├── redis.hcl
│   │   ├── s3.hcl
│   │   └── secrets-n-roles.hcl
│   └── dev/
│       ├── deployment_env.hcl      # Environment-level variables (region, project, tags)
│       ├── non-purgeable/          # Stateful or expensive resources (VPC, RDS, Redis, ECR, S3, ALB, CF)
│       └── purgeable/              # ECS service definitions that can be stopped and redeployed safely
└── _modules/                       # Local Terraform modules
    ├── terraform-aws-alb/
    ├── terraform-aws-cloudfront/
    ├── terraform-aws-ec2/
    ├── terraform-aws-ecr/
    ├── terraform-aws-ecs/
    ├── terraform-aws-efs/
    ├── terraform-aws-rds/
    ├── terraform-aws-redis/
    ├── terraform-aws-s3/
    ├── terraform-aws-secrets-n-roles/
    └── terraform-aws-vpc/
```

### Purgeable vs Non-purgeable

`non-purgeable` resources hold state or are expensive to recreate: VPC, RDS, Redis, ECR, EFS, S3, ALB, CloudFront, IAM roles, and the EC2 bastion.

`purgeable` resources are ECS service definitions. They can be destroyed and redeployed without data loss, which makes them practical to stop outside business hours for cost savings.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9.5
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.67.15
- AWS CLI configured with credentials that have sufficient IAM permissions
- An ACM certificate in your deployment region for the ALB HTTPS listener

You can install both tools on Ubuntu/Debian with the script below:

```bash
#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_VERSION="1.9.5"
TERRAGRUNT_VERSION="v0.67.15"
ARCH="linux_amd64"

curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${ARCH}.zip
unzip terraform_${TERRAFORM_VERSION}_${ARCH}.zip
sudo mv terraform /usr/local/bin/
rm terraform_${TERRAFORM_VERSION}_${ARCH}.zip

curl -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_${ARCH}
chmod +x terragrunt
sudo mv terragrunt /usr/local/bin/

terraform -version
terragrunt --version
```

## Setup

### 1. Bootstrap remote state

Create the S3 bucket and DynamoDB table before running any module. The bucket name follows the pattern `${application}-${team}-statefiles`. With the defaults in `deployment_env.hcl` this is `platform-devops-statefiles` and the lock table is `ff-locks`.

```bash
aws s3api create-bucket \
  --bucket platform-devops-statefiles \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table \
  --table-name ff-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 2. Export required environment variables

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-south-1

# Domain names used in ALB routing rules and CloudFront aliases
export APP_DOMAIN=app.anilrajrimal.com.np
export FORMS_DOMAIN=forms.anilrajrimal.com.np

# ACM certificate ARN for the ALB HTTPS listener (must exist in the deployment region)
export ACM_TLS_CERT_BACKEND_ARN=arn:aws:acm:ap-south-1:ACCOUNT_ID:certificate/CERT_ID

# CloudFront aliases
export CLOUDFRONT_DIST_ALIASES=app.anilrajrimal.com.np

# S3 bucket used to serve pre-built frontend HTML
export FRONTEND_STATIC_BUCKET=platform-devops-dev-frontend-static
```

### 3. Deploy non-purgeable infrastructure

VPC must be applied first. All other non-purgeable modules can follow in any order since Terragrunt resolves dependencies automatically.

```bash
# Deploy all non-purgeable modules in dependency order
cd deployments/dev/non-purgeable
terragrunt run-all apply
```

Or individually:

```bash
cd deployments/dev/non-purgeable/vpc && terragrunt apply
cd deployments/dev/non-purgeable/rds && terragrunt apply
# ... and so on for each module
```

### 4. Push container images to ECR

Before deploying ECS services, build and push your application images to the ECR repositories created in step 3.

### 5. Deploy purgeable services

```bash
cd deployments/dev/purgeable
terragrunt run-all apply
```

## Terragrunt Workflow

Terragrunt adds three capabilities on top of Terraform:

**DRY configuration via `include`**
Each module's `terragrunt.hcl` includes `root.hcl` (provider and remote state config) and an `_envcommon/*.hcl` file (default inputs for that component type). Environment-specific values are set in the module's own `inputs` block and override the common defaults.

**Automatic remote state**
`root.hcl` generates a `backend.tf` for every module, storing state at:
```
s3://${application}-${team}-statefiles/${environment}/${module_path}/terraform.tfstate
```
DynamoDB provides state locking to prevent concurrent applies.

**Dependency management**
`dependency` blocks allow modules to read outputs from other modules (e.g., ECS services pull VPC subnet IDs and ALB target group ARNs at apply time). Terragrunt resolves apply order automatically when using `run-all`.

## CI/CD Pipeline

`bitbucket-pipelines.yml` provides two custom pipelines:

| Pipeline | Description |
|---|---|
| `infrastructure-deploy` | Runs `plan` (automatic) then `apply` (manual gate) for a selected module |
| `infrastructure-destroy` | Validates module path then runs `destroy` (manual gate) |

Both pipelines accept `ENVIRONMENT_NAME`, `ENVIRONMENT_TYPE`, and `MODULE_NAME` as variables.

Required Bitbucket repository variables:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `ACM_TLS_CERT_BACKEND_ARN`
- `APP_DOMAIN`
- `FORMS_DOMAIN`
- `FRONTEND_STATIC_BUCKET`

## Adding a New Environment

1. Copy `deployments/dev/` to `deployments/staging/`
2. Edit `deployments/staging/deployment_env.hcl` and update `environment`, `project`, `short_name`, and any sizing overrides
3. Adjust resource sizes in the new environment's module HCL files as needed (e.g., smaller RDS ACU range for staging)
4. Add `staging` to the pipeline `ENVIRONMENT_NAME` allowed values

## Security Considerations

- No AWS credentials or account identifiers are stored in code. Sensitive values are injected via environment variables or Secrets Manager at runtime.
- RDS has `deletion_protection = true` and `public_access = false` in all environments.
- ECR repositories use KMS encryption with automatic key rotation and scan on push.
- S3 buckets have no public bucket policies.
- ECS task roles scope permissions to specific S3 bucket ARNs and required API actions only.
- Redis clusters are in private subnets restricted to the VPC CIDR. For production, enable `at_rest_encryption_enabled` and `transit_encryption_enabled`.
- The ACM wildcard certificate for CloudFront is provisioned in `us-east-1` (a CloudFront requirement). The ALB certificate must be in the deployment region.

## Future Improvements

- Add `staging` and `prod` environment directories with appropriately sized resources
- Enable Redis encryption at rest and in transit for non-dev environments
- Attach WAF rules to CloudFront distributions
- Migrate CI/CD pipeline to GitHub Actions
- Add Infracost to the CI pipeline for automated cost estimation
- Enable VPC Flow Logs with CloudWatch retention policies
- Add RDS cross-region snapshot copy for disaster recovery
