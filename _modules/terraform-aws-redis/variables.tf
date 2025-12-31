# Required variables
variable "org_meta" {
  description = "Organisation domain and top level domain"
  type = object({
    name       = string
    short_name = string
    url        = string
  })
}

variable "project_meta" {
  description = "Metadata relating to the project for which the database is being created"
  type = object({
    name       = string
    short_name = string
    version    = string
    url        = string
  })
}

variable "resource_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
}

variable "deployment_environment" {
  description = "Deployment flavour or variant identified by this name"
  type        = string
}

variable "redis_identifier" {
  description = "Main/Cache identifier for redis instance"
  type        = string
}

# Redis configuration
variable "redis_config" {
  description = "Redis configuration settings"
  type = object({
    version                 = optional(string, "7.0")
    port                    = optional(number, 6379)
    parameter_group_name    = optional(string, null)
    node_type               = optional(string, "cache.t3.micro")
    num_cache_clusters      = optional(number, 1)
    replicas_per_node_group = optional(number, 0)
    num_node_groups         = optional(number, null)
    multi_az_enabled        = optional(bool, false)
    automatic_failover      = optional(bool, false)
  })
  default = {}
}

# Networking configuration
variable "network_config" {
  description = "Network configuration for Redis"
  type = object({
    vpc_id                  = optional(string, null)
    subnet_ids              = optional(list(string), [])
    subnet_group_name       = optional(string, null)
    security_group_ids      = optional(list(string), [])
    create_security_group   = optional(bool, true)
    allowed_cidr_blocks     = optional(list(string), ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"])
    allowed_security_groups = optional(list(string), [])
  })
  default = {}
}

# Security configuration
variable "security_config" {
  description = "Security configuration for Redis"
  type = object({
    at_rest_encryption_enabled = optional(bool, true)
    transit_encryption_enabled = optional(bool, true)
    auth_token_enabled         = optional(bool, true)
    # auth_token                 = optional(string, null)
    kms_key_id = optional(string, null)
    log_delivery_configuration = optional(list(object({
      destination      = string
      destination_type = string
      log_format       = string
      log_type         = string
    })), [])
  })
  default = {}
}

# Maintenance and backup configuration
variable "maintenance_config" {
  description = "Maintenance and backup configuration"
  type = object({
    maintenance_window         = optional(string, "sun:05:00-sun:06:00")
    snapshot_retention_limit   = optional(number, 5)
    snapshot_window            = optional(string, "03:00-04:00")
    auto_minor_version_upgrade = optional(bool, true)
    apply_immediately          = optional(bool, false)
    notification_topic_arn     = optional(string, null)
    final_snapshot_identifier  = optional(string, null)
  })
  default = {}
}

# Monitoring and alerting
variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enable_cloudwatch_logs = optional(bool, false)
    slow_log_enabled       = optional(bool, false)
    engine_log_enabled     = optional(bool, false)
  })
  default = {}
}

# Tags
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = null
}

variable "owner" {
  description = "Owner of the Redis resources"
  type        = string
  default     = null
}
