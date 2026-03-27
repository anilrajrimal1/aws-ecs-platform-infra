include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ec2.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.1.0"
# }

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("deployment_env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "efs" {
  config_path = "../efs"
}

dependency "s3-fe" {
  config_path = "../s3-fe"
}

dependency "s3-forms-fe" {
  config_path = "../s3-forms-fe"
}

dependency "s3" {
  config_path = "../s3"
}

inputs = {
  vpc_id                                   = dependency.vpc.outputs.vpc_id
  ec2_subnet_id                            = dependency.vpc.outputs.public_subnets[0]
  ec2_instance_ami                         = "ami-0bc691261a82b32bc"
  create_ssh_key_pair                      = true
  ec2_root_vol_size                        = 30
  create_n_attach_ec2_iam_instance_profile = true
  ec2_instance_profile_policy_statements = [
    {
      sid    = "RetrieveSecretManager"
      effect = "Allow"

      resources = [
        "*"
      ]

      actions = [
        "secretsmanager:GetSecretValue"
      ]
    },
    {
      sid    = "S3Access"
      effect = "Allow"
      resources = [
        dependency.s3.outputs.s3_bucket_arn,
        "${dependency.s3.outputs.s3_bucket_arn}/*",
        dependency.s3-fe.outputs.s3_bucket_arn,
        "${dependency.s3-fe.outputs.s3_bucket_arn}/*",
        dependency.s3-forms-fe.outputs.s3_bucket_arn,
        "${dependency.s3-forms-fe.outputs.s3_bucket_arn}/*"
      ]
      actions = [
        "s3:ListBucket",
        "s3:ListAllMyBuckets",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
    },
    {
      sid    = "ECRAccess"
      effect = "Allow"
      resources = [
        "*"
      ]
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
      ]
    },
    {
      sid    = "ECSAccess"
      effect = "Allow"
      resources = [
        "*"
      ]
      actions = [
        "ecs:DescribeClusters",
        "ecs:ListClusters",
        "ecs:UpdateService",
        "ecs:ListServices",
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:DescribeTasks",
        "ecs:ListTasks"
      ]
    }
  ]

  ec2_user_data = templatefile("user_data.yml", {
    HOSTNAME = join("-", [
      include.envcommon.locals.application,
      include.envcommon.locals.environment,
      include.envcommon.locals.team
      ]
    ),
    EFS_ID     = dependency.efs.outputs.file_system_id,
    AWS_REGION = include.envcommon.locals.aws_region,
    }
  )
}
