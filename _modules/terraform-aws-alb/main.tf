## Removed in favor of direct arn value 
# data "aws_acm_certificate" "wildcard" {
#   domain      = var.acm_tls_cert_domain
#   statuses    = ["ISSUED"]
#   most_recent = true

#   key_types = ["RSA_2048", "RSA_3072", "RSA_4096", "EC_prime256v1", "EC_secp384r1", "EC_secp521r1"]
# }

resource "aws_security_group" "public" {
  name_prefix = "alb_public_access"
  description = "Public access for load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTPS connections from everywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTP connections to allow redirection to HTTPS"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "lb-app" {
  for_each    = var.target_groups
  name_prefix = "alb_app_access"
  description = "App access from self"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow access connections to port"
    from_port        = var.target_groups[each.key].port
    to_port          = var.target_groups[each.key].port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "public" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups = concat(
    [
      aws_security_group.public.id
    ],
    # [
    #   for sg in aws_security_group.lb-app : sg.id
    # ]
  )
  subnets = var.alb_subnets

  enable_deletion_protection = false
  # ip_address_type            = "dualstack"
  ip_address_type = "ipv4"

  idle_timeout = 1800
}

#TODO: Add support for multiple tg
resource "aws_lb_target_group" "main" {
  for_each        = var.target_groups
  name            = lookup(var.target_groups[each.key], "name")
  port            = lookup(var.target_groups[each.key], "port", 80)
  protocol        = lookup(var.target_groups[each.key], "protocol", "HTTP")
  vpc_id          = var.vpc_id
  target_type     = "ip"
  ip_address_type = var.ip_address_type

  dynamic "health_check" {
    for_each = lookup(var.target_groups[each.key], "health_check", null) != null ? [lookup(var.target_groups[each.key], "health_check")] : []

    content {
      enabled = lookup(health_check.value, "enabled", true)
      path    = lookup(health_check.value, "path", "/")
      port    = lookup(health_check.value, "port", "traffic-port")

      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 2)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 5)
      interval            = lookup(health_check.value, "interval", 30)
      timeout             = lookup(health_check.value, "timeout", 10)
      matcher             = lookup(health_check.value, "matcher", "200-499")

    }

  }

  # health_check {
  #   enabled = true
  #   path    = var.health_check_path
  #   port    = var.app_port

  #   healthy_threshold   = 2
  #   unhealthy_threshold = 3
  #   interval            = 30
  #   timeout             = 6
  #   matcher             = "200-499"
  # }
}

resource "aws_lb_listener" "secure" {
  load_balancer_arn = aws_lb.public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.tls_cipher_policy
  certificate_arn   = var.acm_tls_cert_backend_arn

  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.main[0].arn
  # }

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to Test!"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "insecure" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

