
resource "aws_acm_certificate" "main" {
  count             = lookup(var.create_acm_certificate_configs, "create_acm_certificate") ? 1 : 0
  domain_name       = lookup(var.create_acm_certificate_configs, "certificate_domain_name")
  validation_method = "DNS"
  region            = "us-east-1"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "main" {
  for_each = {
    for dvo in lookup(var.create_acm_certificate_configs, "route_53_zone_id_for_validation") != null ? aws_acm_certificate.main[0].domain_validation_options : [] :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }

  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = lookup(var.create_acm_certificate_configs, "route_53_zone_id_for_validation") != null ? lookup(var.create_acm_certificate_configs, "route_53_zone_id_for_validation") : null
}
