variable "s3_bucket_name" {
  description = "Name of the S3 bucket to be used as the origin"
  type        = string
}

variable "create_s3_bucket_policy" {
  description = "Whether to create an S3 bucket policy to allow CloudFront access"
  type        = bool
  default     = true
}

variable "enabled" {
  description = "Whether the distribution is enabled to accept user requests"
  type        = bool
  default     = true
}

variable "create_acm_certificate_configs" {
  description = "Configuration for creating an ACM certificate"
  type = object({
    create_acm_certificate          = bool
    certificate_domain_name         = string
    route_53_zone_id_for_validation = optional(string, null)
  })

  default = {
    certificate_domain_name         = "example.com"
    create_acm_certificate          = false
    route_53_zone_id_for_validation = null
  }
}


variable "alb_origins" {
  description = "List of ALB origins"
  type = list(object({
    domain_name              = string
    origin_id                = string
    origin_path              = optional(string, "")
    http_port                = optional(number, 80)
    https_port               = optional(number, 443)
    origin_protocol_policy   = optional(string, "https-only")
    origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
    origin_keepalive_timeout = optional(number, 5)
    origin_read_timeout      = optional(number, 30)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "s3_origins" {
  description = "List of S3 origins"
  type = list(object({
    domain_name            = string
    origin_id              = string
    origin_path            = optional(string, "")
    use_oai                = optional(bool, false)
    origin_access_identity = optional(string, "")
  }))
  default = []
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "distribution_comment" {
  description = "Comment for the distribution"
  type        = string
  default     = "CloudFront distribution for S3"
}

variable "default_root_object" {
  description = "Object that CloudFront returns when a viewer requests the root URL"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Price class for the distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards to the origin"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "forward_query_string" {
  description = "Whether to forward query strings to the origin"
  type        = bool
  default     = false
}

variable "forward_cookies" {
  description = "Specifies which cookies to forward to the origin (none, all, whitelist)"
  type        = string
  default     = "none"
}

variable "viewer_protocol_policy" {
  description = "Protocol that viewers can use to access the content (allow-all, redirect-to-https, https-only)"
  type        = string
  default     = "redirect-to-https"
}

variable "min_ttl" {
  description = "Minimum time objects stay in CloudFront cache"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default time objects stay in CloudFront cache"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum time objects stay in CloudFront cache"
  type        = number
  default     = 86400
}

variable "compress" {
  description = "Whether CloudFront automatically compresses certain files"
  type        = bool
  default     = true
}

variable "geo_restriction_type" {
  description = "Method to restrict distribution of your content by country (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to assign to the distribution"
  type        = map(string)
  default     = {}
}

variable "use_default_certificate" {
  description = "Whether to use the default CloudFront certificate"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate to use with the distribution"
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "custom_error_response_page_404_enabled" {
  description = "Whether to enable a custom error response for 404 errors"
  type        = bool
  default     = false
}

variable "custom_error_response_page_404" {
  description = "Path to the custom error page for 404 errors"
  type        = string
  default     = "/404.html"
}

variable "custom_error_response_page_404_ttl" {
  description = "Minimum TTL for the custom error response"
  type        = number
  default     = 60
}
variable "custom_error_response_page_403_enabled" {
  description = "Whether to enable a custom error response for 403 errors"
  type        = bool
  default     = false
}

variable "custom_error_response_page_403" {
  description = "Path to the custom error page for 403 errors"
  type        = string
  default     = "/403.html"
}

variable "custom_error_response_page_403_ttl" {
  description = "Minimum TTL for the custom error response"
  type        = number
  default     = 60
}

#variables for dynamic custom_error_response block
variable "custom_error_response_pages" {
  description = "List of custom error response pages"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = []
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "default_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    compress                   = optional(bool, true)
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    cache_policy_id            = optional(string, null)
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)
    realtime_log_config_arn    = optional(string, null)

    # Legacy cache behavior settings (used when cache_policy_id is not specified)
    forward_query_string    = optional(bool, false)
    query_string_cache_keys = optional(list(string), [])
    forward_headers         = optional(list(string), [])
    forward_cookies         = optional(string, "none")
    whitelisted_cookies     = optional(list(string), [])
    min_ttl                 = optional(number, 0)
    default_ttl             = optional(number, 3600)
    max_ttl                 = optional(number, 86400)

    # Lambda@Edge and CloudFront Functions
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])

    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  })
}

variable "ordered_cache_behaviors" {
  description = "List of ordered cache behaviors"
  type = list(object({
    path_pattern               = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    compress                   = optional(bool, true)
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    cache_policy_id            = optional(string, null)
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)
    realtime_log_config_arn    = optional(string, null)

    # Legacy cache behavior settings
    forward_query_string    = optional(bool, false)
    query_string_cache_keys = optional(list(string), [])
    forward_headers         = optional(list(string), [])
    forward_cookies         = optional(string, "none")
    whitelisted_cookies     = optional(list(string), [])
    min_ttl                 = optional(number, 0)
    default_ttl             = optional(number, 3600)
    max_ttl                 = optional(number, 86400)

    # Lambda@Edge and CloudFront Functions
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])

    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
  default = []
}

variable "custom_error_responses" {
  description = "List of custom error responses"
  type = list(object({
    error_code            = number
    error_caching_min_ttl = optional(number, 10)
    response_code         = optional(number, null)
    response_page_path    = optional(string, null)
  }))
  default = []
}

variable "geo_restriction" {
  description = "Geographic restriction configuration"
  type = object({
    restriction_type = optional(string, "none")
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
    locations        = []
  }
}

variable "logging_config" {
  description = "Logging configuration for CloudFront"
  type = object({
    bucket          = string
    include_cookies = optional(bool, false)
    prefix          = optional(string, "")
  })
  default = null
}

variable "prevent_destroy" {
  description = "Prevent destruction of the CloudFront distribution"
  type        = bool
  default     = false
}


variable "ssl_certificate" {
  description = "SSL certificate configuration"
  type = object({
    acm_certificate_arn      = optional(string, null)
    ssl_support_method       = optional(string, "sni-only")
    minimum_protocol_version = optional(string, "TLSv1.2_2021")
  })
  default = {
    acm_certificate_arn      = null
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

variable "existing_s3_oac_id" {
  description = "ID of the existing S3 Origin Access Control (OAC) to be used with CloudFront"
  type        = string
  default     = null
}
