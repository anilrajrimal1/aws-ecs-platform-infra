# ================================
# File: main.tf
# ================================

# Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = local.resource_prefix
  description          = "Redis cluster for ${local.resource_prefix}"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.redis_config.version
  node_type            = var.redis_config.node_type
  port                 = var.redis_config.port
  parameter_group_name = local.parameter_group_name

  # Cluster configuration
  num_cache_clusters      = local.cluster_mode_enabled ? null : var.redis_config.num_cache_clusters
  replicas_per_node_group = local.cluster_mode_enabled ? var.redis_config.replicas_per_node_group : null
  num_node_groups         = local.cluster_mode_enabled ? var.redis_config.num_node_groups : null

  # High availability
  multi_az_enabled           = var.redis_config.multi_az_enabled
  automatic_failover_enabled = local.automatic_failover_enabled

  # Network configuration
  subnet_group_name = var.network_config.subnet_group_name != null ? var.network_config.subnet_group_name : aws_elasticache_subnet_group.redis[0].name
  security_group_ids = length(var.network_config.security_group_ids) > 0 ? var.network_config.security_group_ids : (
    var.network_config.create_security_group ? [aws_security_group.redis[0].id] : []
  )

  # Security configuration
  at_rest_encryption_enabled = var.security_config.at_rest_encryption_enabled
  transit_encryption_enabled = var.security_config.transit_encryption_enabled
  auth_token                 = var.security_config.transit_encryption_enabled ? local.auth_token : null
  kms_key_id                 = var.security_config.kms_key_id

  # Maintenance and backup
  maintenance_window         = var.maintenance_config.maintenance_window
  snapshot_retention_limit   = var.maintenance_config.snapshot_retention_limit
  snapshot_window            = var.maintenance_config.snapshot_window
  auto_minor_version_upgrade = var.maintenance_config.auto_minor_version_upgrade
  apply_immediately          = var.maintenance_config.apply_immediately
  notification_topic_arn     = var.maintenance_config.notification_topic_arn
  final_snapshot_identifier  = var.maintenance_config.final_snapshot_identifier

  # Logging
  dynamic "log_delivery_configuration" {
    for_each = var.security_config.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to auth_token to prevent recreation
      auth_token,
    ]
  }
}
