resource "aws_instance" "ec2_instance" {
  ami                         = var.ec2_instance_ami
  instance_type               = var.instance_type
  key_name                    = var.create_ssh_key_pair ? aws_key_pair.ssh_key[0].key_name : var.existing_ssh_key_pair_name
  subnet_id                   = var.ec2_subnet_id
  vpc_security_group_ids      = concat(var.ec2_sec_grps, [aws_security_group.ec2_sec_grp[0].id])
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.ec2_iam_instance_profile != "" ? var.ec2_iam_instance_profile : var.create_n_attach_ec2_iam_instance_profile ? aws_iam_instance_profile.ec2_instance_profile[0].name : null
  user_data                   = var.ec2_user_data

  root_block_device {
    volume_size = var.ec2_root_vol_size
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = local.ec2_identifier
  }
}

# Add and attach elastic IP

resource "aws_eip" "this" {
  count  = var.create_eip ? 1 : 0
  domain = "vpc"
  tags = { Name = "${local.ec2_identifier}-eip" }
}

resource "aws_eip_association" "this" {
  count         = var.create_eip ? 1 : 0
  instance_id   = aws_instance.ec2_instance.id
  allocation_id = aws_eip.this[0].id
}
