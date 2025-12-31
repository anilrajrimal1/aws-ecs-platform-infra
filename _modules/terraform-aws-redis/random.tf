# ================================
# File: random.tf
# ================================

# Generate auth token if needed
resource "random_password" "auth_token" {
  count   = var.security_config.auth_token_enabled ? 1 : 0
  length  = 32
  special = false

  lifecycle {
    ignore_changes = [length, special]
  }
}
