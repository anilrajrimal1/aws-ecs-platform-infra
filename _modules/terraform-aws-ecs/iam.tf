data "aws_iam_policy_document" "ecs-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs-agent" {
  description           = "ECS Task Execution Role used by ECS Agent"
  assume_role_policy    = data.aws_iam_policy_document.ecs-assume-role.json
  force_detach_policies = true
  name_prefix           = "ecs-task-execution-agent-role-"
}

data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

locals {
  secrets_manager_resources = (
    length(var.container_secrets) > 0 ? 
    [for secret in var.container_secrets : secret.valueFrom] : 
    ["*"]
  )
}

data "aws_iam_policy_document" "secrets-manager" {
  statement {
    sid     = "1"
    actions = ["secretsmanager:GetSecretValue"]
    resources = local.secrets_manager_resources
  }

  statement {
    sid     = "2"
    actions = ["kms:Decrypt"]
    resources = [
      data.aws_kms_alias.secretsmanager.arn
    ]
  }
}

resource "aws_iam_policy" "secrets-manager" {
  name_prefix = "secrets-manager"
  description = "IAM Policy that allows access to Secrets Manager entries"
  policy      = data.aws_iam_policy_document.secrets-manager.json
}

resource "aws_iam_role_policy_attachment" "secrets-manager" {
  role       = aws_iam_role.ecs-agent.name
  policy_arn = aws_iam_policy.secrets-manager.arn
}

data "aws_iam_policy_document" "s3" {
  # Statement for getting secret values from Secrets Manager
  statement {
    sid = "1"

    actions = [
    "s3:GetObject", ]

    # Dynamically reference the ARNs of the secrets
    resources = [
      for c_envfile in var.container_envfiles : c_envfile.value
    ]
  }
}

resource "aws_iam_policy" "s3" {
  name_prefix = "s3"
  description = "IAM Policy that allows access to S3 env file"
  policy      = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.ecs-agent.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "aws_iam_role_policy_attachment" "task-exec-role-policy-default" {
  role       = aws_iam_role.ecs-agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
