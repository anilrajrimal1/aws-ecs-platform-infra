resource "aws_appautoscaling_target" "main" {
  max_capacity = lookup(var.scaling_target_values, "container_max_count")
  min_capacity = lookup(var.scaling_target_values, "container_min_count")

  resource_id = join("/", [
    "service",
    local.aws_ecs_cluster_name,
    aws_ecs_service.main.name
  ])

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU High Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.cpu_scaling_config != null ? 1 : 0
  alarm_name          = "${lookup(var.container_settings, "service_name")}/HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_scaling_config.evaluation_periods
  period              = var.cpu_scaling_config.period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = var.cpu_scaling_config.threshold
  alarm_description   = "Alarm when CPU exceeds ${var.cpu_scaling_config.threshold}%"
  dimensions = {
    ClusterName = local.aws_ecs_cluster_name
    ServiceName = aws_ecs_service.main.name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up_by_cpu[count.index].arn]
  ok_actions    = [aws_appautoscaling_policy.scale_down_by_cpu[count.index].arn]
}

# CPU Scale-Up Policy
resource "aws_appautoscaling_policy" "scale_up_by_cpu" {
  count              = var.cpu_scaling_config != null ? 1 : 0
  name               = "scale-up-by-cpu"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.cpu_scaling_config.scale_up_cooldown
    dynamic "step_adjustment" {
      for_each = var.cpu_scaling_config.scale_up_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}

# CPU Scale-Down Policy
resource "aws_appautoscaling_policy" "scale_down_by_cpu" {
  count              = var.cpu_scaling_config != null ? 1 : 0
  name               = "scale-down-by-cpu"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.cpu_scaling_config.scale_down_cooldown
    dynamic "step_adjustment" {
      for_each = var.cpu_scaling_config.scale_down_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}

# Memory High Alarm
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.memory_scaling_config != null ? 1 : 0
  alarm_name          = "${lookup(var.container_settings, "service_name")}/HighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.memory_scaling_config.evaluation_periods
  period              = var.memory_scaling_config.period
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = var.memory_scaling_config.threshold
  alarm_description   = "Alarm when memory exceeds ${var.memory_scaling_config.threshold}%"
  dimensions = {
    ClusterName = local.aws_ecs_cluster_name
    ServiceName = aws_ecs_service.main.name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up_by_memory[count.index].arn]
  ok_actions    = [aws_appautoscaling_policy.scale_down_by_memory[count.index].arn]
}

# Memory Scale-Up Policy
resource "aws_appautoscaling_policy" "scale_up_by_memory" {
  count              = var.memory_scaling_config != null ? 1 : 0
  name               = "scale-up-by-memory"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.memory_scaling_config.scale_up_cooldown
    dynamic "step_adjustment" {
      for_each = var.memory_scaling_config.scale_up_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}

# Memory Scale-Down Policy
resource "aws_appautoscaling_policy" "scale_down_by_memory" {
  count              = var.memory_scaling_config != null ? 1 : 0
  name               = "scale-down-by-memory"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.memory_scaling_config.scale_down_cooldown
    dynamic "step_adjustment" {
      for_each = var.memory_scaling_config.scale_down_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}

# Request Count Scale-Up Alarm
resource "aws_cloudwatch_metric_alarm" "request_count_scale_up" {
  count               = var.request_scaling_config != null ? 1 : 0
  alarm_name          = "${lookup(var.container_settings, "service_name")}/RequestCountScaleUp"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.request_scaling_config.evaluation_periods
  period              = var.request_scaling_config.period
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  threshold           = var.request_scaling_config.threshold
  alarm_description   = "Alarm when request count per target exceeds ${var.request_scaling_config.threshold}"
  dimensions = {
    LoadBalancer = lookup(var.load_balancer_settings, "arn_suffix")
    TargetGroup  = lookup(var.load_balancer_settings, "target_group_arn_suffix")
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up_by_requests[count.index].arn]
  ok_actions    = [aws_appautoscaling_policy.scale_down_by_requests[count.index].arn]
}

# Request Count Scale-Up Policy
resource "aws_appautoscaling_policy" "scale_up_by_requests" {
  count              = var.request_scaling_config != null ? 1 : 0
  name               = "scale-up-by-requests"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.request_scaling_config.scale_up_cooldown
    dynamic "step_adjustment" {
      for_each = var.request_scaling_config.scale_up_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}

# Request Count Scale-Down Policy
resource "aws_appautoscaling_policy" "scale_down_by_requests" {
  count              = var.request_scaling_config != null ? 1 : 0
  name               = "scale-down-by-requests"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.request_scaling_config.scale_down_cooldown
    dynamic "step_adjustment" {
      for_each = var.request_scaling_config.scale_down_steps
      content {
        metric_interval_lower_bound = step_adjustment.value.lower_bound
        metric_interval_upper_bound = step_adjustment.value.upper_bound
        scaling_adjustment          = step_adjustment.value.adjustment
      }
    }
  }
}
