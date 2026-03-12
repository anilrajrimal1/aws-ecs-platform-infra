include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/alb.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.0"
# }

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  # General VPC Configuration
  vpc_id      = dependency.vpc.outputs.vpc_id
  alb_subnets = dependency.vpc.outputs.public_subnets

  target_groups = {
    web = {
      name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "web", "tg")
      port     = 8000
      protocol = "HTTP"
      health_check = {
        enabled             = true
        path                = "/accounts/login/"
        port                = "8000"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
        matcher             = "200-499"
      }
    }
    service = {
      name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "service", "tg")
      port     = 8383
      protocol = "HTTP"
      health_check = {
        enabled             = true
        path                = "/"
        port                = "8383"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
        matcher             = "200-499"
      }
    }

    fastapi = {
      name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "fastapi", "tg")
      port     = 8000
      protocol = "HTTP"
      health_check = {
        enabled             = true
        path                = "/api/v3/docs"
        port                = "8000"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 3
        unhealthy_threshold = 3
        matcher             = "200-299"
      }
    }

    # mail = {
    #   name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "mail", "tg")
    #   port     = 8383
    #   protocol = "HTTP"
    #   health_check = {
    #     enabled             = true
    #     path                = "/"
    #     port                = "8383"
    #     interval            = 30
    #     timeout             = 5
    #     healthy_threshold   = 5
    #     unhealthy_threshold = 2
    #     matcher             = "200-299"
    #   }
    # }

    # pyxform = {
    #   name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "pyxform", "tg")
    #   port     = 8383
    #   protocol = "HTTP"
    #   health_check = {
    #     enabled             = true
    #     path                = "/"
    #     port                = "8383"
    #     interval            = 30
    #     timeout             = 5
    #     healthy_threshold   = 5
    #     unhealthy_threshold = 2
    #     matcher             = "200-299"
    #   }
    # }

    enketo = {
      name     = format("%s-%s-%s-%s", include.envcommon.locals.application, include.envcommon.locals.environment, "enketo", "tg")
      port     = 8005
      protocol = "HTTP"
      health_check = {
        enabled             = true
        path                = "/-/"
        port                = "8005"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
        matcher             = "200-499"
      }
    }
  }

  # Define fixed response rules  -> maintenance
  # Uncomment this and re-apply alb for turning on
  # fixed_response_rules = {
  #   maintenance_root = {
  #     priority    = 10
  #     action_type = "fixed-response"
  #     conditions = {
  #       host_header  = [get_env("APP_DOMAIN", "app.anilrajrimal.com.np")]
  #       path_pattern = ["/"]
  #     }
  #     fixed_response = {
  #       content_type = "text/plain"
  #       message_body = "maintenance"
  #       status_code  = "503"
  #     }
  #   }
  #   submission_block = {
  #     priority    = 20
  #     action_type = "fixed-response"
  #     conditions = {
  #       host_header  = [get_env("FORMS_DOMAIN", "forms.anilrajrimal.com.np")]
  #       path_pattern = ["/v1/*/submission", "/v1/*/submission/*"]
  #     }
  #     fixed_response = {
  #       content_type = "text/plain"
  #       message_body = "Submission is Blocked by Admin"
  #       status_code  = "405"
  #     }
  #   }
  # }

  # Define routing rules configuration
  forward_rules = {
    fastapi = {
      priority = 1
      #target_group_key should match keyname in target_groups
      target_group_key = "fastapi"
      conditions = {
        host_header  = [get_env("APP_DOMAIN", "app.anilrajrimal.com.np")]
        path_pattern = ["/api/v3/*"]
      }
      action_type = "forward"
    }

    web = {
      priority = 2
      #target_group_key should match keyname in target_groups
      target_group_key = "web"
      conditions = {
        host_header = [get_env("APP_DOMAIN", "app.anilrajrimal.com.np")]
      }
      action_type = "forward"
    }
    enketo = {
      priority = 3
      #target_group_key should match keyname in target_groups
      target_group_key = "enketo"
      conditions = {
        host_header  = [get_env("FORMS_DOMAIN", "forms.anilrajrimal.com.np")]
        path_pattern = ["/-/*"]
      }
      action_type = "forward"
    }
    service = {
      priority = 4
      #target_group_key should match keyname in target_groups
      target_group_key = "service"
      conditions = {
        host_header = [get_env("FORMS_DOMAIN", "forms.anilrajrimal.com.np")]
      }
      action_type = "forward"
    }
  }

  # Define redirect rules
  # redirect_rules = {
  #   app_redirect = {
  #     priority = 6
  #     conditions = {
  #       host_header = [var.domain]
  #     }
  #     redirect = {
  #       host        = "${var.app_subdomain}.${var.domain}"
  #       status_code = "HTTP_301"
  #     }
  #   }

  #   mobile_to_web_redirect = {
  #     priority = 9
  #     conditions = {
  #       host_header = ["links.${var.domain}"]
  #     }
  #     redirect = {
  #       host        = "${var.app_subdomain}.${var.domain}"
  #       path        = "/#{path}"
  #       port        = "#{port}"
  #       protocol    = "#{protocol}"
  #       query       = "#{query}"
  #       status_code = "HTTP_301"
  #     }
  #   }
  # }

  # Define fixed response rules
  # fixed_response_rules = {
  #   asset_link = {
  #     priority = 8
  #     conditions = {
  #       host_header  = ["links.${var.domain}"]
  #       path_pattern = ["/.well-known/assetlinks.json"]
  #     }
  #     fixed_response = {
  #       content_type = "application/json"
  #       message_body = file("${path.module}/${var.assetlinks_file_path}")
  #       status_code  = "200"
  #     }
  #   }
  # }

  # TLS and Certificate Configuration
  # Set ACM_TLS_CERT_BACKEND_ARN in CI/CD environment variables or export locally before running.
  acm_tls_cert_backend_arn = get_env("ACM_TLS_CERT_BACKEND_ARN", "")


}
