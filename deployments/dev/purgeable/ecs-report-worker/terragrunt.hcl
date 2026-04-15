# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecs.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.2.1"
# }

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("deployment_env.hcl"))
  # common_ecs_envs  = read_terragrunt_config(find_in_parent_folders("common-ecs-env.hcl"))
}

# ---------------------------------------------------------------------------------------------------------------------
# We don't need to override any of the common parameters for this environment, so we don't specify any other parameters.
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = "../../non-purgeable/vpc"
}

dependency "alb" {
  config_path = "../../non-purgeable/alb"
}

dependency "rds" {
  config_path = "../../non-purgeable/rds"
}

dependency "s3" {
  config_path = "../../non-purgeable/s3"
}

dependency "redis-main" {
  config_path = "../../non-purgeable/redis-main"
}

dependency "redis-cache" {
  config_path = "../../non-purgeable/redis-cache"
}

dependency "ecr" {
  config_path = "../../non-purgeable/ecr"
}

dependency "efs" {
  config_path = "../../non-purgeable/efs"
}

dependency "secrets-n-roles" {
  config_path = "../../non-purgeable/secrets-n-roles"
}

dependency "ecs-web" {
  config_path = "../ecs-web"
}

## Add in any new inputs that you want to overide.
inputs = {
  # Inputs from dependencies (Rarely changed)
  service_subnets         = dependency.vpc.outputs.private_subnets
  aws_vpc_id              = dependency.vpc.outputs.vpc_id
  service_security_groups = [dependency.alb.outputs.load_balancer_public_security_group]
  deployment_environment  = local.environment_vars.locals.environment

  task_role_arn = dependency.secrets-n-roles.outputs.ecs_task_role_arn

  #Enable Execute Command
  enable_execute_command = true

  ## Default tested resources needed for fastapi container. Override using ../<environment>/purgeable/ecs/terragrunt.hcl
  container_capacity = {
    cpu       = 2048
    memory_mb = 8192
  }

  container_envfiles = [{
    type  = "s3"
    value = "arn:aws:s3:::${dependency.s3.outputs.bucket_name}/app_environment/platform.env"
  }]

  # Merge secrets with: key:ValueFrom together
  container_secrets = concat(
    dependency.secrets-n-roles.outputs.container_secrets,
    dependency.rds.outputs.database_config_as_ecs_secrets_inputs,
    # dependency.redis-main.outputs.redis_config_as_ecs_secrets_inputs,
    # dependency.redis-cache.outputs.redis_config_as_ecs_secrets_inputs
  )

  container_commands = [
    "celery",
    "-A",
    "platform",
    "worker",
    "-l",
    "INFO",
    "--concurrency=2",
    "--prefetch-multiplier=1",
    "-Q",
    "report"
  ]

  ## Task count for ECS services.
  tasks_count = {
    desired_count   = 1
    min_healthy_pct = 100
    max_pct         = 400
  }

  ## Scaling Policy Target Values
  scaling_target_values = {
    container_min_count = 1
    container_max_count = 2
  }

  # Merge non-sensetive together
  container_envvars = merge(
    dependency.rds.outputs.database_config_as_ecs_inputs,
    dependency.redis-main.outputs.redis_config_as_ecs_inputs,
    dependency.redis-cache.outputs.redis_config_as_ecs_inputs,
    # These envs are passed to the container entrypoint.sh file
    # While spinning up ecs task, it will fetch GCP creds and app template file from respective s3/keys
    {
      CONFIG_BUCKET=dependency.s3.outputs.bucket_name
      CONFIG_FILES="credentials/credentials.json:/code/credentials.json,credentials/service_account.json:/code/service_account.json"

      FRONTEND_STATIC_BUCKET      = get_env("FRONTEND_STATIC_BUCKET", "")
      FRONTEND_TEMPLATE_S3_KEY="apphtml/index.html"
      FRONTEND_TEMPLATE_FILE_PATH="/code/core/templates/core/app.html"
    },
    # {
    #   # Add any additional environment variables here
    #   ENKETO_BASE_URL = "http://enketo.${local.environment_vars.locals.short_name}.${local.environment_vars.locals.environment}.internal:8005/-"
    # }
    # local.common_ecs_envs.locals.envs
  )

  # Override image to use "main" image tag (default is environment variable eg. develop)
  container_settings = {
    app_port         = 8000
    cpu_architecture = "X86_64"
    image_url        = dependency.ecr.outputs.ecr_repos_map_by_key["web"]
    image_tag        = "latest"
    service_name     = "report_worker"
    # service_name     = format("%s-%s-%s-%s", local.environment_vars.locals.application, local.environment_vars.locals.team, local.environment_vars.locals.environment, "service")
  }

  #loggin config
  log_configuration = {
    logdriver = "awslogs"
    options = {
      awslogs-group         = format("%s-%s-%s-%s", local.environment_vars.locals.application, local.environment_vars.locals.team, local.environment_vars.locals.environment, "report_worker")
      awslogs-region        = local.environment_vars.locals.aws_region
      awslogs-stream-prefix = "report_worker"
    }
  }

  cpu_scaling_config = {
    enabled             = true
    threshold           = 60
    evaluation_periods  = 1
    period              = 30
    scale_up_cooldown   = 60
    scale_down_cooldown = 180
    scale_up_steps = [
      { lower_bound = 0, upper_bound = 20, adjustment = 1 },
      { lower_bound = 20, upper_bound = null, adjustment = 2 }
    ]
    scale_down_steps = [
      { lower_bound = null, upper_bound = -25, adjustment = -1 },
      # { lower_bound = -10, upper_bound = 0, adjustment = -1 }
    ]
  }

  memory_scaling_config = {
    enabled             = true
    threshold           = 70
    evaluation_periods  = 1
    period              = 30
    scale_up_cooldown   = 60
    scale_down_cooldown = 180
    scale_up_steps = [
      { lower_bound = 0, upper_bound = 20, adjustment = 1 },
      { lower_bound = 20, upper_bound = null, adjustment = 2 }
    ]
    scale_down_steps = [
      { lower_bound = null, upper_bound = -25, adjustment = -1 },
    ]
  }

}
