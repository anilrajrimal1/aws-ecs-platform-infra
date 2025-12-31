resource "random_pet" "ecr" {
}

locals {
  ecr_identifier = join("-", [
    lookup(var.project_meta, "name"),
    lookup(var.project_meta, "environment"),
    lookup(var.project_meta, "team"),
    "ecr",
    random_pet.ecr.id
    ]
  )
}

# KMS key for ECR encryption
resource "aws_kms_key" "encryption_key_ecr" {
  description             = "KMS ECR key 1"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  tags = {
    "Name" = "${local.ecr_identifier}-key"
  }
}

resource "aws_kms_alias" "kms_alias_ecr" {
  name          = "alias/${local.ecr_identifier}-key"
  target_key_id = aws_kms_key.encryption_key_ecr.key_id
}


# CREATE AWS PRIVATE REPO
resource "aws_ecr_repository" "private_repo" {
  # For each ECR repository defined in the variable, create a private repository
  for_each = var.ecr_repos
  name     = var.ecr_repos[each.key].name
  #image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.encryption_key_ecr.arn
  }
  tags = {
    Name = "Private ECR Repository for ${var.ecr_repos[each.key].name}"
  }
}


resource "aws_ecr_lifecycle_policy" "lifecycle" {
  for_each   = var.ecr_repos
  repository = aws_ecr_repository.private_repo[each.key].name
  depends_on = [aws_ecr_repository.private_repo]
  policy     = var.lifecycle_policy
}

