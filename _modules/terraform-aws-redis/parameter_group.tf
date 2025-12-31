# ================================
# File: parameter_group.tf
# ================================

resource "aws_elasticache_parameter_group" "redis" {
  count       = var.redis_config.parameter_group_name == null ? 1 : 0
  family      = local.cluster_mode_enabled ? "redis${var.redis_config.version}" : "redis${var.redis_config.version}"
  name        = "${local.resource_prefix}-params"
  description = "Parameter group for Redis ${local.resource_prefix}"

  # Common Redis optimizations
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  dynamic "parameter" {
    for_each = var.monitoring_config.slow_log_enabled ? [1] : []
    content {
      name  = "slowlog-log-slower-than"
      value = "10000"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
