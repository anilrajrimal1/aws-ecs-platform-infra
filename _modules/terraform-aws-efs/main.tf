# EFS File System
locals {
  efs_identifier = var.efs_name != null ? var.efs_name : join("-", [
    lookup(var.project_meta, "name"),
    lookup(var.project_meta, "environment"),
    lookup(var.project_meta, "team"),
    "efs",
    random_pet.efs.id
    ]
  )
}

resource "aws_efs_file_system" "efs_main" {
  creation_token   = local.efs_identifier
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  # If throughput mode is provisioned, set the provisioned throughput
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  encrypted = var.encrypted
  #   kms_key_id = var.kms_key_id

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != "NEVER" ? [var.transition_to_ia] : []
    content {
      transition_to_ia = var.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != "NEVER" ? [var.transition_to_ia] : []
    content {

      transition_to_primary_storage_class = var.transition_to_primary_storage_class
    }
  }

  tags = {
    Name = local.efs_identifier
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sec_grp" {
  name_prefix = "${local.efs_identifier}-efs_sec_grp"
  description = "Allow EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.efs_identifier}-efs_sec_grp"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "efs_main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.efs_main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sec_grp.id]
}

# EFS Access Point for Secrets
resource "aws_efs_access_point" "access_point" {
  for_each       = var.access_points
  file_system_id = aws_efs_file_system.efs_main.id
  posix_user {
    gid = each.value.gid
    uid = each.value.uid
  }

  root_directory {
    path = each.value.path
    creation_info {
      owner_gid   = each.value.gid
      owner_uid   = each.value.uid
      permissions = each.value.permissions
    }
  }

  tags = {
    Name = "${local.efs_identifier}-${each.value.ap_name}-AP"
  }

}

# # EFS Backup Policy
# resource "aws_efs_backup_policy" "efs_main" {
#   file_system_id = aws_efs_file_system.efs_main.id

#   backup_policy {
#     status = var.backup_policy_status
#   }
# }
