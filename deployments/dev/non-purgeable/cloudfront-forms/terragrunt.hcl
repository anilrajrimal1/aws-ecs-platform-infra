include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/cloudfront.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# terraform {
#   source = "${include.envcommon.locals.base_source_url}?ref=v1.1.0"
# }

dependency "s3-odk-fe" {
  config_path = "../s3-odk-fe"
}

dependency "alb" {
  config_path = "../alb"
}


inputs = {
  # S3 bucket configuration - only need to provide the bucket name
  s3_bucket_name = dependency.s3-odk-fe.outputs.bucket_name
  # S3 Origins
  s3_origins = [
    {
      domain_name = dependency.s3-odk-fe.outputs.bucket_regional_domain_name
      origin_id   = "S3-${dependency.s3-odk-fe.outputs.bucket_name}"
      origin_path = "/odkhtml"
    }
  ]
  # ALB Origins
  alb_origins = [
    {
      domain_name            = dependency.alb.outputs.load_balancer_dns
      origin_id              = "ALB-forms-${dependency.alb.outputs.load_balancer_dns}"
      origin_protocol_policy = "https-only"
      custom_headers = [
        {
          name  = "X-Forwarded-Proto"
          value = "https"
        }
      ]
    }
  ]
  create_s3_bucket_policy = true
  # Default Cache Behavior
  default_behavior = {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${dependency.s3-odk-fe.outputs.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    # cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    # origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin
  }

  # Ordered Cache Behaviors
  ordered_cache_behaviors = [
    {
      path_pattern             = "/v?/*"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = "ALB-forms-${dependency.alb.outputs.load_balancer_dns}"
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
    },
    {
      path_pattern             = "/-/*"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = "ALB-forms-${dependency.alb.outputs.load_balancer_dns}"
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
    },
    {
      path_pattern             = "/"
      allowed_methods          = ["GET", "HEAD"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = "S3-${dependency.s3-odk-fe.outputs.bucket_name}"
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
      origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin
    }
  ]

  # Set CLOUDFRONT_DIST_ALIASES to your actual domain(s) separated by spaces.
  aliases = split(" ", get_env("CLOUDFRONT_DIST_ALIASES", "forms.anilrajrimal.com.np"))

  # CloudFront configuration
  enabled              = true
  is_ipv6_enabled      = true
  distribution_comment = "Frontend Static distribution for ${include.envcommon.locals.distribution_name}"
  default_root_object  = "index.html"

  # Custom error pages
  custom_error_responses = [
    # {
    #   error_code            = 403
    #   response_page_path    = "/index.html"
    #   response_code         = "200"
    #   error_caching_min_ttl = 0
    # },
    # {
    #   error_code            = 404
    #   response_page_path    = "/index.html"
    #   response_code         = "200"
    #   error_caching_min_ttl = 0
    # }
  ]

  # Price class - choose one of: [
  # - PriceClass_100 (US, Canada, Europe)
  # - PriceClass_200 (PriceClass_100 + South America, Australia, New Zealand, and parts of Asia)
  # - PriceClass_All (All regions)
  # ]
  price_class = "PriceClass_All"

  # If you already have SSL cert in us-east-1, provide these:
  # ssl_certificate = {
  #   acm_certificate_arn      = "arn:aws:acm:us-east-1:xxxxxxxx:certificate/aaa-bbb-ccc-ddd"
  #   ssl_support_method       = "sni-only"
  #   minimum_protocol_version = "TLSv1.2_2021"
  # }
  # Else If you want to create certificate in us-east-1 for cloudfront, set this below to true
  create_acm_certificate_configs = {
    create_acm_certificate  = true
    certificate_domain_name = "*.anilrajrimal.com.np"
    # route_53_zone_id_for_validation = "" # provide if you manage Route53 and want automatic DNS validation
  }
}
