# Log Group Defination for the ECS Task
resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_configuration.options.awslogs-group
  retention_in_days = 7
}

resource "aws_service_discovery_service" "primary" {
  for_each = var.service_registries
  name     = lookup(var.container_settings, "service_name")
  dns_config {
    namespace_id = each.value.namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  # health_check_custom_config {
  #   failure_threshold = 1
  # }
}


resource "aws_ecs_service" "main" {
  name            = lookup(var.container_settings, "service_name")
  cluster         = local.aws_ecs_cluster_arn
  task_definition = aws_ecs_task_definition.main.arn

  enable_execute_command = var.enable_execute_command

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn = aws_service_discovery_service.primary[service_registries.key].arn
    }
  }

  dynamic "alarms" {
    for_each = lookup(var.alarm_settings, "enable") ? lookup(var.alarm_settings, "names") : []

    content {
      alarm_names = lookup(var.alarm_settings, "names")
      enable      = lookup(var.alarm_settings, "enable")
      rollback    = lookup(var.alarm_settings, "rollback")
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = var.deployment_controller
  }

  desired_count                      = lookup(var.tasks_count, "desired_count")
  deployment_maximum_percent         = lookup(var.tasks_count, "max_pct")
  deployment_minimum_healthy_percent = lookup(var.tasks_count, "min_healthy_pct")

  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = lookup(var.load_balancer_settings, "enabled") ? try(var.health_check_grace_period_seconds, 20) : null

  launch_type = "FARGATE"

  dynamic "load_balancer" {
    for_each = lookup(var.load_balancer_settings, "enabled") ? ["a"] : []

    content {
      target_group_arn = lookup(var.load_balancer_settings, "target_group_arn")
      container_name   = lookup(var.container_settings, "service_name")
      container_port   = lookup(var.container_settings, "app_port")
    }
  }

  network_configuration {
    subnets          = var.service_subnets
    security_groups  = concat(var.service_security_groups)
    assign_public_ip = false
  }

  propagate_tags = var.propagate_tags_from

  force_new_deployment = var.force_new_deployment

  triggers = {
    redeployment = plantimestamp()
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }
}
