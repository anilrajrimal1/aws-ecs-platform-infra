# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mysql. The common variables for each environment to
# deploy mysql are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If any environment
# needs to deploy a different module version, it should redefine this block with a different ref to override the
# deployed version.
terraform {
  source = "${dirname(find_in_parent_folders("_modules"))}/_modules/terraform-aws-ecr"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("deployment_env.hcl"))

  # Extract out common variables for reuse
  environment = local.environment_vars.locals.environment
  application = local.environment_vars.locals.application
  team        = local.environment_vars.locals.team

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the terraform block in the child terragrunt configurations.
  base_source_url = "git::https://github.com/hotosm/terraform-aws-ecr/"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
# Defaults,  overridden by env.hcl

inputs = {
  project_meta = {
    name        = local.environment_vars.locals.project
    environment = local.environment_vars.locals.environment
    team        = local.environment_vars.locals.team
  }
  ecr_repos = {
    web = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "web")
      description = "ECR repository for the Django web application"
    }
    service = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "service")
      description = "ECR repository for the form collection service"
    }
    mail = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "mail")
      description = "ECR repository for the mail relay service"
    }
    pyxform = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "pyxform")
      description = "ECR repository for the XLSForm conversion service"
    }
    enketo = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "enketo")
      description = "ECR repository for the form rendering service"
    }
    fastapi = {
      name        = format("%s/%s/%s/%s", local.application, local.team, local.environment, "fastapi")
      description = "ECR repository for the async API service"
    }
  }
}
