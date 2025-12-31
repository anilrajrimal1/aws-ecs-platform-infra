# ================================
# File: locals.tf
# ================================


locals {
  # Resource naming
  resource_prefix = var.resource_prefix != null ? var.resource_prefix : join("-", [
    lookup(var.project_meta, "name"),
    "redis",
    var.deployment_environment
    ]
  )

  # Determine deployment mode
  cluster_mode_enabled = var.redis_config.num_node_groups != null && var.redis_config.num_node_groups > 1

  # Auth token management
  auth_token = var.security_config.auth_token_enabled ? random_password.auth_token[0].result : null

  # Automatic failover should be enabled for multi-AZ or cluster mode
  automatic_failover_enabled = var.redis_config.automatic_failover || var.redis_config.multi_az_enabled || local.cluster_mode_enabled

  # Parameter group selection
  parameter_group_name = var.redis_config.parameter_group_name != null ? var.redis_config.parameter_group_name : (
    local.cluster_mode_enabled ? "default.redis${replace(var.redis_config.version, ".", "")}.cluster.on" :
    "default.redis${replace(var.redis_config.version, ".", "")}"
  )

  # Subnet configuration
  use_default_vpc = var.network_config.vpc_id == null && length(var.network_config.subnet_ids) == 0
  vpc_id          = local.use_default_vpc ? data.aws_vpc.default[0].id : var.network_config.vpc_id
  subnet_ids      = local.use_default_vpc ? data.aws_subnets.default[0].ids : var.network_config.subnet_ids
}
