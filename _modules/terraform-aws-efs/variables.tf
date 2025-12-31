resource "random_pet" "efs" {
}

variable "project_meta" {
  description = "Metadata relating to the project for which the EFS is being created"
  type = object({
    name        = string
    environment = string
    team        = string
  })
}

variable "efs_name" {
  description = "EFS name"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID in which to host resources"
  type        = string

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "VPC ID must start with `vpc-`"
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where EFS mount targets will be created"
  type        = list(string)
}

variable "performance_mode" {
  description = "EFS performance mode"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode"
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "Throughput mode must be either bursting or provisioned."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiBps (only used if throughput_mode is provisioned)"
  type        = number
  default     = 100
}

variable "encrypted" {
  description = "Enable encryption for EFS file system"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "transition_to_ia" {
  description = "Transition to Infrequent Access storage class"
  type        = string
  default     = "NEVER"

  validation {
    condition = contains([
      "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS",
      "AFTER_60_DAYS", "AFTER_90_DAYS", "NEVER"
    ], var.transition_to_ia)
    error_message = "Invalid transition_to_ia value."
  }
}

variable "transition_to_primary_storage_class" {
  description = "Transition back to primary storage class"
  type        = string
  default     = "AFTER_1_ACCESS"

  validation {
    condition = contains([
      "AFTER_1_ACCESS"
    ], var.transition_to_primary_storage_class)
    error_message = "Invalid transition_to_primary_storage_class value."
  }
}

variable "backup_policy_status" {
  description = "EFS backup policy status"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.backup_policy_status)
    error_message = "Backup policy status must be either ENABLED or DISABLED."
  }
}

# Access Point Variables
variable "access_points" {
  description = "Configuration for EFS access points"
  type = map(
    object({
      ap_name     = string
      uid         = number
      gid         = number
      permissions = string
      path        = string
    })
  )
  default = {}
}
