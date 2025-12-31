######
output "file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.efs_main.id
}

output "file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.efs_main.arn
}

output "dns_name" {
  description = "EFS DNS name"
  value       = aws_efs_file_system.efs_main.dns_name
}

output "access_point_ids" {
  description = "Access point IDs"
  value = {
    for key, ap in aws_efs_access_point.access_point : key => ap.id
  }
}

output "mount_target_ids" {
  description = "EFS mount target IDs"
  value       = aws_efs_mount_target.efs_main[*].id
}
