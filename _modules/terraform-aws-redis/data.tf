# ================================
# File: data.tf
# ================================

# Get current AWS region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Default VPC and subnets (fallback)
data "aws_vpc" "default" {
  count   = local.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = local.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
