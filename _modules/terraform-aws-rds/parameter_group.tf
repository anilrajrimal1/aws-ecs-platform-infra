# DB Cluster Parameter Group (for Aurora cluster-level settings)
resource "aws_rds_cluster_parameter_group" "database" {
  name_prefix = join("-", [
    lookup(var.project_meta, "name"),
    var.deployment_environment,
    "aurora-pg"
  ])

  family      = "aurora-postgresql${lookup(var.database, "parameter_group_family", "16")}"
  description = "Cluster parameter group for ${lookup(var.project_meta, "name")} ${var.deployment_environment}"

  dynamic "parameter" {
    for_each = lookup(var.database, "rds_cluster_parameters", [])
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = {
    Name        = "${lookup(var.project_meta, "name")}-${var.deployment_environment}-cluster-pg"
    Environment = var.deployment_environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group (for instance-level settings)
resource "aws_db_parameter_group" "serverless_writer" {
  name_prefix = join("-", [
    lookup(var.project_meta, "name"),
    var.deployment_environment,
    "aurora-pg-instance"
  ])

  family      = "aurora-postgresql${lookup(var.database, "parameter_group_family", "16")}"
  description = "Instance parameter group for ${lookup(var.project_meta, "name")} ${var.deployment_environment}"

  dynamic "parameter" {
    for_each = lookup(var.database, "rds_db_parameters", [])
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = {
    Name        = "${lookup(var.project_meta, "name")}-${var.deployment_environment}-instance-pg"
    Environment = var.deployment_environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Update the aws_rds_cluster resource to use the cluster parameter group
# Add this line to your existing aws_rds_cluster.database resource:
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.database.name

# Update the aws_rds_cluster_instance resource to use the instance parameter group
# Add this line to your existing aws_rds_cluster_instance.database resource:
#   db_parameter_group_name = aws_db_parameter_group.database.name
