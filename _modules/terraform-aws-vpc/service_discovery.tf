resource "aws_service_discovery_private_dns_namespace" "primary" {
  name = join(".", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment,
    "internal"
    ]
  )
  vpc = aws_vpc.primary.id
}

resource "aws_service_discovery_service" "primary" {
  name = join("-", [
    lookup(var.project_meta, "short_name"),
    var.deployment_environment,
    "service-discovery"
    ]
  )

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.primary.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
