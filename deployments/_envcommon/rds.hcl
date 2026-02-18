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
  source = "${dirname(find_in_parent_folders("_modules"))}/_modules/terraform-aws-rds"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("deployment_env.hcl"))

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the terraform block in the child terragrunt configurations.
  base_source_url = "git::https://github.com/hotosm/terraform-aws-rds/"

  # Generate a safe DB name & admin user for RDS 
  # (letters + numbers only, start with a letter)
  # Handles if the locals.environment mistakenly set with symbol
  db_name_safe = lower(replace(join("", [
    local.environment_vars.locals.short_name,
    local.environment_vars.locals.environment,
  ]), "-", "_"))
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
# Defaults,  overridden by env.hcl

inputs = {

  project_meta = {
    name       = local.environment_vars.locals.project
    short_name = local.environment_vars.locals.short_name
    team       = local.environment_vars.locals.team
    version    = local.environment_vars.locals.version
    url        = local.environment_vars.locals.url
  }

  org_meta = {
    name       = local.environment_vars.locals.project
    short_name = local.environment_vars.locals.short_name
    url        = local.environment_vars.locals.url
  }

  deployment_environment = local.environment_vars.locals.environment
  deletion_protection    = true
  // default_tags           = var.default_tags

  database = {
    name                   = local.db_name_safe
    admin_user             = local.db_name_safe
    password_length        = 48
    engine_version         = 15
    port                   = 5432
    parameter_group_family = "15"
    rds_cluster_parameters = [
      {
        name         = "shared_preload_libraries"
        value        = "pg_stat_statements"
        apply_method = "pending-reboot"
      },
      {
        name  = "log_statement"
        value = "ddl"
      },
      {
        name  = "log_min_duration_statement"
        value = "5000"
      },

      # Aurora Serverless v2 with 4-16 ACU scaling
      # 4 ACU = ~8GB RAM, 16 ACU = ~32GB RAM
      # Using conservative settings for minimum capacity
      {
        # For 4 ACU (8GB): (8 * 1024 * 1024) / 8 = 1048576 (1GB)
        # For 16 ACU (32GB): (32 * 1024 * 1024) / 8 = 4194304 (4GB)
        # Setting for minimum capacity to avoid issues when scaled down
        name         = "shared_buffers"
        value        = "GREATEST({DBInstanceClassMemory/32768}, 2097152)" # max 1/4 of memory
        apply_method = "pending-reboot"
      },
      {
        # Dynamic calculation based on instance memory
        # This will adjust automatically as ACU scales
        name  = "effective_cache_size"
        value = "{DBInstanceClassMemory/16384}"
      },
      {
        name         = "work_mem"
        value        = "131072" # 128MB in KB
        apply_method = "immediate"
      }
    ],
    rds_db_parameters = [
      {
      name         = "max_connections"
      value        = "5000"
      apply_method = "pending-reboot"
      }
    ]

  }

  network_type = "IPV4"
}
