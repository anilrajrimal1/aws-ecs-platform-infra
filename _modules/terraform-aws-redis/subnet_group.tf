# ================================
# File: subnet_group.tf
# ================================

resource "aws_elasticache_subnet_group" "redis" {
  count      = var.network_config.subnet_group_name == null ? 1 : 0
  name       = "${local.resource_prefix}-subnet-group"
  subnet_ids = local.subnet_ids

  lifecycle {
    create_before_destroy = true
  }
}
