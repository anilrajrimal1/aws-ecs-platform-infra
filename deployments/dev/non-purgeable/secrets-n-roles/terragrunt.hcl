include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/secrets-n-roles.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}"
# }

inputs = {
  ## Override them by exporting the vars to the environment before running Terragrunt.
  ## Example:
  ## export APP_ENV_VARS='{"key1":"value1","key2":"value2"}'
  container_secrets = [
    # {
    #   name      = "APP_ENV_VARS"
    #   valueFrom = get_env("APP_ENV_VARS", "")
    # }
  ]
}
