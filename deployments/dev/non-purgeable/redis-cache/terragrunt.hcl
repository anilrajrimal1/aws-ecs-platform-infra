include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/redis.hcl"
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.0"
# }

dependency "vpc" {
  config_path = "../vpc"
}

# Add in any new inputs that you want to overide.
inputs = {
  resource_prefix  = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "redis", "cache")
  redis_identifier = "CACHE"

  redis_config = {
    node_type            = "cache.t3.micro"
    version              = "7.0"
    num_node_groups      = 1
    parameter_group_name = "default.redis7"
    # num_cache_clusters    = 3
    # multi_az_enabled      = true
    # automatic_failover    = true
  }

  network_config = {
    vpc_id              = dependency.vpc.outputs.vpc_id
    subnet_ids          = dependency.vpc.outputs.private_subnets
    allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr]
  }

  security_config = {
    at_rest_encryption_enabled = false
    transit_encryption_enabled = false
    auth_token_enabled         = false
  }

  maintenance_config = {
    maintenance_window         = "sun:02:00-sun:03:00"
    snapshot_retention_limit   = 7
    auto_minor_version_upgrade = false # Control upgrades in prod
  }

}
