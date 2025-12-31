# ================================
# File: outputs.tf
# ================================

# Primary outputs
output "redis_replication_group_id" {
  description = "The ID of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "redis_replication_group_arn" {
  description = "The ARN of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.arn
}

# Connection information
output "redis_primary_endpoint" {
  description = "The primary endpoint for the Redis replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_configuration_endpoint" {
  description = "The configuration endpoint for the Redis replication group (cluster mode)"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "redis_reader_endpoint" {
  description = "The reader endpoint for the Redis replication group"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_port" {
  description = "The port number on which Redis accepts connections"
  value       = aws_elasticache_replication_group.redis.port
}

# Cluster information
output "redis_cluster_enabled" {
  description = "Whether Redis cluster mode is enabled"
  value       = local.cluster_mode_enabled
}

output "redis_member_clusters" {
  description = "The identifiers of all the nodes that are part of this replication group"
  value       = aws_elasticache_replication_group.redis.member_clusters
}

# Network information
output "redis_subnet_group_name" {
  description = "The name of the subnet group used by Redis"
  value       = var.network_config.subnet_group_name != null ? var.network_config.subnet_group_name : aws_elasticache_subnet_group.redis[0].name
}

output "redis_security_group_ids" {
  description = "The security group IDs associated with Redis"
  value       = aws_elasticache_replication_group.redis.security_group_ids
}

# Security information
output "redis_auth_token_enabled" {
  description = "Whether auth token authentication is enabled"
  value       = var.security_config.auth_token_enabled
  sensitive   = false
}

output "redis_auth_token" {
  description = "The auth token for Redis (if enabled)"
  value       = local.auth_token
  sensitive   = true
}

output "redis_encryption_at_rest_enabled" {
  description = "Whether encryption at rest is enabled"
  value       = aws_elasticache_replication_group.redis.at_rest_encryption_enabled
}

output "redis_encryption_in_transit_enabled" {
  description = "Whether encryption in transit is enabled"
  value       = aws_elasticache_replication_group.redis.transit_encryption_enabled
}

# Additional metadata
output "redis_engine_version" {
  description = "The Redis engine version"
  value       = aws_elasticache_replication_group.redis.engine_version_actual
}

output "redis_parameter_group_name" {
  description = "The parameter group name used by Redis"
  value       = aws_elasticache_replication_group.redis.parameter_group_name
}

output "redis_config_as_ecs_inputs" {
  description = "This is to easily merge with ECS module"
  value = {
    "ENKETO_${var.redis_identifier}_REDIS_HOST" = aws_elasticache_replication_group.redis.primary_endpoint_address
    "ENKETO_${var.redis_identifier}_REDIS_PORT" = aws_elasticache_replication_group.redis.port
  }
}

output "redis_config_as_ecs_secrets_inputs" {
  description = "This is to easily merge with ECS module"
  value = [
    lookup(var.security_config, "auth_token_enabled", false) ?
    {
      name      = "${replace(upper(local.resource_prefix), "-", "_")}_REDIS_PASSWORD"
      valueFrom = aws_secretsmanager_secret_version.redis-credentials-password[0].arn
      } : {
      name  = "${replace(upper(local.resource_prefix), "-", "_")}_REDIS_PASSWORD"
      value = ""
    }
  ]
}
