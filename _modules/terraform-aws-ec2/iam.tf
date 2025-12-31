data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "GenericAssumeRoleEC2"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  count              = var.create_n_attach_ec2_iam_instance_profile ? 1 : 0
  name               = "${local.ec2_identifier}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Name = "${local.ec2_identifier}-role"
  }
}

resource "aws_iam_policy" "ec2_policy" {
  count       = var.create_n_attach_ec2_iam_instance_profile ? 1 : 0
  name        = "${local.ec2_identifier}-policy"
  description = "Instance profile policy for EC2"
  policy      = data.aws_iam_policy_document.ec2_instance_profile_policy.json
  tags = {
    Name = "${local.ec2_identifier}-policy"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_attachment" {
  count      = var.create_n_attach_ec2_iam_instance_profile ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = aws_iam_policy.ec2_policy[0].arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  count = var.create_n_attach_ec2_iam_instance_profile ? 1 : 0
  name  = "${local.ec2_identifier}-profile"
  role  = aws_iam_role.ec2_role[0].name
}

data "aws_iam_policy_document" "ec2_instance_profile_policy" {
  dynamic "statement" {
    for_each = {
      for index, statement in var.ec2_instance_profile_policy_statements :
      index => statement
    }

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      resources = statement.value.resources
      actions   = statement.value.actions
    }
  }
}
