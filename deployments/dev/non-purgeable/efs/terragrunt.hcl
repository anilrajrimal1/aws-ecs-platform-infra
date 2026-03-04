include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/efs.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("deployment_env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnets
  access_points = {
    secrets = {
      ap_name     = "secrets"
      path        = "/secrets"
      uid         = 1000
      gid         = 1000
      permissions = "0755"
    }
    mail = {
      ap_name     = "mail"
      path        = "/mail"
      uid         = 1000
      gid         = 1000
      permissions = "0755"
    }
  }
}
