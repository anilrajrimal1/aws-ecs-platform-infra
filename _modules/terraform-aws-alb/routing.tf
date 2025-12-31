# main.tf
# Forward action listener rules
resource "aws_lb_listener_rule" "forward_rules" {
  for_each = var.forward_rules

  listener_arn = aws_lb_listener.secure.arn
  priority     = each.value.priority

  action {
    type             = each.value.action_type
    target_group_arn = aws_lb_target_group.main[each.key].arn
  }

  # Host header condition (always present)
  condition {
    host_header {
      values = each.value.conditions.host_header
    }
  }

  # Path pattern condition (conditional)
  dynamic "condition" {
    for_each = lookup(each.value.conditions, "path_pattern", null) != null ? [1] : []
    content {
      path_pattern {
        values = each.value.conditions.path_pattern
      }
    }
  }

  tags = {
    Name = "${var.alb_name}-${each.key}_routing_rule"
    Type = "forward"
  }
}

# Redirect action listener rules
resource "aws_lb_listener_rule" "redirect_rules" {
  for_each = var.redirect_rules

  listener_arn = aws_lb_listener.secure.arn
  priority     = each.value.priority

  action {
    type = "redirect"
    redirect {
      host        = lookup(each.value.redirect, "host", "#{host}")
      path        = lookup(each.value.redirect, "path", "#{path}")
      port        = lookup(each.value.redirect, "port", "#{port}")
      protocol    = lookup(each.value.redirect, "protocol", "#{protocol}")
      query       = lookup(each.value.redirect, "query", "#{query}")
      status_code = each.value.redirect.status_code
    }
  }

  condition {
    host_header {
      values = each.value.conditions.host_header
    }
  }

  tags = {
    Name = "${var.alb_name}-${each.key}_redirect_rule"
    Type = "redirect"
  }
}

# Fixed response action listener rules
resource "aws_lb_listener_rule" "fixed_response_rules" {
  for_each = var.fixed_response_rules

  listener_arn = aws_lb_listener.secure.arn
  priority     = each.value.priority

  action {
    type = "fixed-response"
    fixed_response {
      content_type = each.value.fixed_response.content_type
      message_body = each.value.fixed_response.message_body
      status_code  = each.value.fixed_response.status_code
    }
  }

  # Host header condition
  condition {
    host_header {
      values = each.value.conditions.host_header
    }
  }

  # Path pattern condition
  dynamic "condition" {
    for_each = lookup(each.value.conditions, "path_pattern", null) != null ? [1] : []
    content {
      path_pattern {
        values = each.value.conditions.path_pattern
      }
    }
  }

  tags = {
    Name = "${var.alb_name}-${each.key}_fixed_response_rule"
    Type = "fixed-response"
  }
}
