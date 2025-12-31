# ================================
# File: security_groups.tf
# ================================

resource "aws_security_group" "redis" {
  count       = var.network_config.create_security_group ? 1 : 0
  name_prefix = "${local.resource_prefix}-redis-"
  description = "Security group for Redis cluster ${local.resource_prefix}"
  vpc_id      = local.vpc_id

  # Redis port access
  dynamic "ingress" {
    for_each = length(var.network_config.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = var.redis_config.port
      to_port     = var.redis_config.port
      protocol    = "tcp"
      cidr_blocks = var.network_config.allowed_cidr_blocks
      description = "Redis access from allowed CIDR blocks"
    }
  }

  # Security group access
  dynamic "ingress" {
    for_each = var.network_config.allowed_security_groups
    content {
      from_port   = var.redis_config.port
      to_port     = var.redis_config.port
      protocol    = "tcp"
      description = "Redis access from security group ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }


  lifecycle {
    create_before_destroy = true
  }
}
