# Get the S3 bucket information using a data source
data "aws_s3_bucket" "origin_bucket" {
  bucket = var.s3_bucket_name
}

# Create Origin Access Control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  count                             = var.existing_s3_oac_id != null ? 0 : 1
  name                              = "OAC for ${var.s3_bucket_name}"
  description                       = "Origin Access Control for S3 bucket ${var.s3_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  comment             = var.distribution_comment
  default_root_object = var.default_root_object
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  # web_acl_id          = var.web_acl_id # Uncomment if you have a WAF Web ACL to associate

  # Dynamic ALB Origins
  dynamic "origin" {
    for_each = var.alb_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = lookup(origin.value, "origin_path", "")

      custom_origin_config {
        http_port                = lookup(origin.value, "http_port", 80)
        https_port               = lookup(origin.value, "https_port", 443)
        origin_protocol_policy   = lookup(origin.value, "origin_protocol_policy", "https-only")
        origin_ssl_protocols     = lookup(origin.value, "origin_ssl_protocols", ["TLSv1.2"])
        origin_keepalive_timeout = lookup(origin.value, "origin_keepalive_timeout", 5)
        origin_read_timeout      = lookup(origin.value, "origin_read_timeout", 60)
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  # Dynamic S3 Origins
  dynamic "origin" {
    for_each = var.s3_origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = lookup(origin.value, "origin_path", "")
      origin_access_control_id = var.existing_s3_oac_id != null ? var.existing_s3_oac_id : aws_cloudfront_origin_access_control.s3_oac[0].id

      dynamic "s3_origin_config" {
        for_each = lookup(origin.value, "use_oai", false) ? [1] : []
        content {
          origin_access_identity = lookup(origin.value, "origin_access_identity", "")
        }
      }
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods            = var.default_behavior.allowed_methods
    cached_methods             = var.default_behavior.cached_methods
    target_origin_id           = var.default_behavior.target_origin_id
    compress                   = lookup(var.default_behavior, "compress", true)
    viewer_protocol_policy     = lookup(var.default_behavior, "viewer_protocol_policy", "redirect-to-https")
    cache_policy_id            = lookup(var.default_behavior, "cache_policy_id", null)
    origin_request_policy_id   = lookup(var.default_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(var.default_behavior, "response_headers_policy_id", null)
    realtime_log_config_arn    = lookup(var.default_behavior, "realtime_log_config_arn", null)

    # Legacy cache behavior settings (used when cache_policy_id is not specified)
    dynamic "forwarded_values" {
      for_each = lookup(var.default_behavior, "cache_policy_id", null) == null ? [1] : []
      content {
        query_string            = lookup(var.default_behavior, "forward_query_string", false)
        query_string_cache_keys = lookup(var.default_behavior, "query_string_cache_keys", [])
        headers                 = lookup(var.default_behavior, "forward_headers", [])

        cookies {
          forward           = lookup(var.default_behavior, "forward_cookies", "none")
          whitelisted_names = lookup(var.default_behavior, "whitelisted_cookies", [])
        }
      }
    }

    # TTL settings (used when cache_policy_id is not specified)
    min_ttl     = lookup(var.default_behavior, "cache_policy_id", null) == null ? lookup(var.default_behavior, "min_ttl", 0) : null
    default_ttl = lookup(var.default_behavior, "cache_policy_id", null) == null ? lookup(var.default_behavior, "default_ttl", 3600) : null
    max_ttl     = lookup(var.default_behavior, "cache_policy_id", null) == null ? lookup(var.default_behavior, "max_ttl", 86400) : null

    # Lambda@Edge functions
    dynamic "lambda_function_association" {
      for_each = lookup(var.default_behavior, "lambda_function_associations", [])
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lookup(lambda_function_association.value, "include_body", false)
      }
    }

    # CloudFront Functions
    dynamic "function_association" {
      for_each = lookup(var.default_behavior, "function_associations", [])
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  # Ordered Cache Behaviors
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern               = ordered_cache_behavior.value.path_pattern
      allowed_methods            = ordered_cache_behavior.value.allowed_methods
      cached_methods             = ordered_cache_behavior.value.cached_methods
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      compress                   = lookup(ordered_cache_behavior.value, "compress", true)
      viewer_protocol_policy     = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", "redirect-to-https")
      cache_policy_id            = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
      origin_request_policy_id   = lookup(ordered_cache_behavior.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(ordered_cache_behavior.value, "response_headers_policy_id", null)
      realtime_log_config_arn    = lookup(ordered_cache_behavior.value, "realtime_log_config_arn", null)

      # Legacy cache behavior settings
      dynamic "forwarded_values" {
        for_each = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? [1] : []
        content {
          query_string            = lookup(ordered_cache_behavior.value, "forward_query_string", false)
          query_string_cache_keys = lookup(ordered_cache_behavior.value, "query_string_cache_keys", [])
          headers                 = lookup(ordered_cache_behavior.value, "forward_headers", [])

          cookies {
            forward           = lookup(ordered_cache_behavior.value, "forward_cookies", "none")
            whitelisted_names = lookup(ordered_cache_behavior.value, "whitelisted_cookies", [])
          }
        }
      }

      # TTL settings
      min_ttl     = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "min_ttl", 0) : null
      default_ttl = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "default_ttl", 3600) : null
      max_ttl     = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "max_ttl", 86400) : null

      # Lambda@Edge functions
      dynamic "lambda_function_association" {
        for_each = lookup(ordered_cache_behavior.value, "lambda_function_associations", [])
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lookup(lambda_function_association.value, "include_body", false)
        }
      }

      # CloudFront Functions
      dynamic "function_association" {
        for_each = lookup(ordered_cache_behavior.value, "function_associations", [])
        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }
    }
  }

  # Custom Error Response
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", 10)
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = lookup(var.geo_restriction, "restriction_type", "none")
      locations        = lookup(var.geo_restriction, "locations", [])
    }
  }

  # SSL Certificate
  viewer_certificate {
    acm_certificate_arn = lookup(var.create_acm_certificate_configs, "create_acm_certificate") ? aws_acm_certificate.main[0].arn : (var.ssl_certificate.acm_certificate_arn != null ? var.ssl_certificate.acm_certificate_arn : null)

    ssl_support_method             = lookup(var.ssl_certificate, "ssl_support_method", "sni-only")
    minimum_protocol_version       = lookup(var.ssl_certificate, "minimum_protocol_version", "TLSv1.2_2021")
    cloudfront_default_certificate = var.ssl_certificate.acm_certificate_arn == null ? !lookup(var.create_acm_certificate_configs, "create_acm_certificate") : false
  }

  # Aliases
  aliases = var.aliases

  # Logging
  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      include_cookies = lookup(logging_config.value, "include_cookies", false)
      bucket          = logging_config.value.bucket
      prefix          = lookup(logging_config.value, "prefix", "")
    }
  }

}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "bucket_policy" {
  count  = var.create_s3_bucket_policy ? 1 : 0
  bucket = data.aws_s3_bucket.origin_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.origin_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}
