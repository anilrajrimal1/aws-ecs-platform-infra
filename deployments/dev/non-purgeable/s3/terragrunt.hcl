include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/s3.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.0.0"
# }

inputs = {
  bucket               = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.team, include.envcommon.locals.environment, "objects")
  attach_public_policy = false
  attach_policy        = false
  versioning = {
    enabled = true
  }
}
