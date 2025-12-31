resource "aws_ecs_cluster" "main" {
  count = var.create_ecs_cluster ? 1 : 0
  name  = "${lookup(var.project_meta, "name")}-${lookup(var.project_meta, "short_name")}-${var.deployment_environment}-${lookup(var.project_meta, "team")}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.default_tags
}


data "aws_ecs_cluster" "main" {
  count = var.create_ecs_cluster ? 0 : 1
  # This data source is used to reference the ECS cluster in other resources
  cluster_name = var.ecs_cluster_name != null ? var.ecs_cluster_name : "${lookup(var.project_meta, "name")}-${lookup(var.project_meta, "short_name")}-${var.deployment_environment}-${lookup(var.project_meta, "team")}-cluster"
}


locals {
  aws_ecs_cluster_name = var.create_ecs_cluster ? aws_ecs_cluster.main[0].name : data.aws_ecs_cluster.main[0].cluster_name
  aws_ecs_cluster_arn  = var.create_ecs_cluster ? aws_ecs_cluster.main[0].arn : data.aws_ecs_cluster.main[0].arn
}
