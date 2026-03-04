include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecr.hcl"
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

