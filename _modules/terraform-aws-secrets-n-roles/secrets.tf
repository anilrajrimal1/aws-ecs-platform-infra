# Resource for AWS Secrets Manager
resource "aws_secretsmanager_secret" "secrets" {
  for_each = {
    for secret in var.container_secrets : secret.name => secret
  }

  name = join("/", [
    lookup(var.project_meta, "name"),
    lookup(var.project_meta, "team"),
    var.deployment_environment,
    "backend",
    each.key
    ]
  )

  description = "Container secret for the ${lookup(var.project_meta, "name")} ${var.deployment_environment} instance"
}

# Define secret versions
resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for secret in var.container_secrets : secret.name => secret
  }

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = each.value.valueFrom
}
