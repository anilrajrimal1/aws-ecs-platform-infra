resource "aws_secretsmanager_secret" "redis-credentials-password" {
  count       = lookup(var.security_config, "auth_token_enabled", false) ? 1 : 0
  description = "Redis connection parameters and access credentials"

  name_prefix = join("/", [
    lookup(var.project_meta, "name"),
    var.deployment_environment,
    var.resource_prefix,
    "PASSWORD"
    ]
  )
}

resource "aws_secretsmanager_secret_version" "redis-credentials-password" {
  count         = lookup(var.security_config, "auth_token_enabled", false) ? 1 : 0
  secret_id     = aws_secretsmanager_secret.redis-credentials-password[0].id
  secret_string = local.auth_token
}

