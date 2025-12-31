variable "deployment_environment" {
  description = "Deployment flavour or variant identified by this name"
  type        = string

  default = "dev"
}

variable "default_tags" {
  description = "Default resource tags to apply to AWS resources"
  type        = map(string)

  default = {
    project        = ""
    maintainer     = ""
    documentation  = ""
    cost_center    = ""
    IaC_Management = "Terraform"
  }
}

variable "aws_region" {
  description = "Region to create log-group for ecs service"
  type        = string
}

variable "container_secrets" {
  description = "Secrets from Secrets Manager to pass to containers"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  nullable = true
  default  = []
}

variable "container_envvars" {
  description = "Environment variables passed on to the containers"
  type        = map(string)

  nullable = true
  default  = null
}

variable "container_envfiles" {
  description = "Environment files to pass on to the containers"
  type = list(object({
    type  = string
    value = string
  }))

  nullable = true
  default  = []

}

variable "container_settings" {
  type = object({
    service_name = string
    app_port     = number
    image_url    = string
    image_tag    = string
  })
}

variable "container_cpu_architecture" {
  description = "CPU architecture of the container host"
  type        = string

  default = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.container_cpu_architecture)
    error_message = "Allowed CPU architectures are x86_64 and ARM64"
  }
}

variable "app_port_protocol" {
  description = "Protocol for the application port"
  type        = string

  default = "tcp"
}

variable "container_commands" {
  description = "Custom container command to run"
  type        = list(string)

  default = null
}

variable "container_capacity" {
  type = map(number)
  default = {
    cpu       = 256
    memory_mb = 512
  }
}

variable "container_security" {

  default = {
    privileged = false
  }
}

# variable "efs_enabled" {
#   description = "Whether to mount an EFS filesystem to the service"
#   type        = bool

#   default = false
# }

# variable "efs_settings" {
#   description = "EFS access and encryption settings"
#   type = object({
#     file_system_id     = string
#     root_directory     = string
#     access_point_id    = string
#     transit_encryption = optional(string, "ENABLED")
#     iam_authz          = optional(string, "DISABLED")
#   })

#   validation {
#     condition = try(lookup(var.efs_settings, "enabled"), false) ? contains(["ENABLED", "DISABLED"], lookup(var.efs_settings, "transit_encryption")) : true

#     error_message = "Transit encryption needs to be ENABLED or DISABLED"
#   }

#   validation {
#     condition = try(lookup(var.efs_settings, "enabled"), false) ? contains(["ENABLED", "DISABLED"], lookup(var.efs_settings, "iam_authz")) : true

#     error_message = "IAM authorization needs to be ENABLED or DISABLED"
#   }

#   default = null

# }

# variable "container_efs_volume_mount_path" {
#   description = "Absolute path on which to mount the EFS volume"
#   type        = string

#   default = "/"
# }

variable "efs_mounts" {
  description = "EFS mounts to attach to the service"
  type = list(object({
    name                   = string
    efs_file_system_id     = string
    efs_transit_encryption = optional(string, "ENABLED")
    efs_access_point_id    = optional(string, null)
    efs_iam_authz          = optional(string, "ENABLED")
    container_path         = string
    read_only              = optional(bool, false)

  }))

  default = []
}

variable "tasks_count" {
  type        = map(number)
  description = "Desired count of replications for service"

  default = {
    desired_count   = 2
    min_healthy_pct = 50
    max_pct         = 200
  }
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Execute"

  default = false
}

variable "log_configuration" {
  description = "Log configuration"
  type = object({
    logdriver = string
    options = object({
      awslogs-group         = string
      awslogs-region        = string
      awslogs-stream-prefix = string
    })
  })

  validation {
    condition = contains([
      "json-file",
      "journald",
      "gelf",
      "fluentd",
      "awslogs",
      "splunk",
      "awsfirelens",
      "syslog"
      ],
    lookup(var.log_configuration, "logdriver"))
    error_message = "Valid values are awslogs, json-file, journald, gelf, fluentd, splunk, awsfirelens and syslog"
  }
}

variable "linux_capabilities" {
  type = map(list(string))

  default = {
    add  = []
    drop = ["NET_RAW", "NET_BIND_SERVICE", "SYS_CHROOT"]
  }

  /**
  validation {
    condition = contains(
      [
        null,
        "CAP_AUDIT_CONTROL",
        "CAP_AUDIT_READ",
        "CAP_AUDIT_WRITE",
        "CAP_BLOCK_SUSPEND",
        "CAP_BPF",
        "CAP_CHECKPOINT_RESTORE",
        "CAP_CHOWN",
        "CAP_DAC_OVERRIDE",
        "CAP_DAC_READ_SEARCH",
        "CAP_FOWNER",
        "CAP_FSETID",
        "CAP_IPC_LOCK",
        "CAP_IPC_OWNER",
        "CAP_KILL",
        "CAP_LEASE",
        "CAP_LINUX_IMMUTABLE",
        "CAP_MAC_ADMIN",
        "CAP_MAC_OVERRIDE",
        "CAP_MKNOD",
        "CAP_NET_ADMIN",
        "CAP_NET_BIND_SERVICE",
        "CAP_NET_BROADCAST",
        "CAP_NET_RAW",
        "CAP_PERFMON",
        "CAP_SETGID",
        "CAP_SETFCAP",
        "CAP_SETPCAP",
        "CAP_SETUID",
        "CAP_SYS_ADMIN",
        "CAP_SYS_BOOT",
        "CAP_SYS_CHROOT",
        "CAP_SYS_MODULE",
        "CAP_SYS_NICE",
        "CAP_SYS_PACCT",
        "CAP_SYS_PTRACE",
        "CAP_SYS_RAWIO",
        "CAP_SYS_RESOURCE",
        "CAP_SYS_TIME",
        "CAP_SYS_TTY_CONFIG",
        "CAP_SYSLOG",
        "CAP_WAKE_ALARM"
      ],
      lookup(var.linux_capabilities, "add")
    )
    error_message = "Value is not a valid Linux Capabilities"
  }
**/
}

variable "deployment_controller" {
  type = string

  default     = "ECS"
  description = "Deployment Controller"

  validation {
    condition     = contains(["ECS", "CODEDEPLOY"], var.deployment_controller)
    error_message = "Allowed values are ECS or CODEDEPLOY"
  }
}

variable "alarm_settings" {
  description = "Alarm Settings"
  type = object({
    enable   = bool
    names    = list(string)
    rollback = bool
  })

  default = {
    names    = []
    enable   = false
    rollback = false
  }
}

variable "service_registries" {
  description = "Service Registries for ECS Service"
  type = map(object({
    namespace_id   = string
    container_name = optional(string)
    port           = optional(number)
    container_port = optional(number)
  }))

  default = {}

}

variable "load_balancer_settings" {
  type = object({
    enabled                 = optional(bool, false)
    arn_suffix              = optional(string)
    target_group_arn        = optional(string)
    target_group_arn_suffix = optional(string)
    scaling_request_count   = optional(number, 50)
  })

  default = {
    enabled                 = false
    arn_suffix              = ""
    target_group_arn        = ""
    target_group_arn_suffix = ""
    scaling_request_count   = 50
  }
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Health check grace period in seconds"

  default = 30
}

variable "scaling_target_values" {
  type = object({
    container_min_count = number
    container_max_count = number
  })

  default = {
    container_min_count = 2
    container_max_count = 20
  }
}

variable "propagate_tags_from" {
  description = "Whether to propagate tags from service or task definition"
  type        = string

  default = "SERVICE"

  validation {
    condition     = contains(["SERVICE", "TASK_DEFINITION"], var.propagate_tags_from)
    error_message = "Valid values for tag propagation are SERVICE or TASK_DEFINITION"
  }
}

variable "service_subnets" {
  description = "List of subnets in which to launch the service containers/tasks"
  type        = list(string)

  nullable = false
}

variable "aws_vpc_id" {
  description = "VPC ID"
  type        = string

  nullable = false
}

variable "service_security_groups" {
  description = "Security groups to attach to service"
  type        = list(string)

  default = []
}

variable "create_ecs_cluster" {
  description = "Create ECS cluster if it does not exist"
  type        = bool

  default = true
}

# These are already generated based on project varibles.
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster in which to launch the services"
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster in which to launch the services"
  type        = string
  nullable    = true
  default     = null
}

variable "task_role_arn" {
  description = "ARN of task (guest-app) role"
  type        = string

  default = null
}

variable "force_new_deployment" {
  description = "Force new deployment everytime?"
  type        = bool

  default = false
}

variable "container_ephemeral_storage" {
  description = "Size of the ephemeral storage in GiB for container"
  type        = number

  default = 21
}

variable "org_meta" {
  description = "Org info for secrets manager prefix"
  type        = map(string)
  # default = {
  #   name       = "anilrajrimal.com.np"
  #   short_name = "test"
  #   url        = "anilrajrimal.com."
  # }
}

variable "project_meta" {
  description = "Metadata relating to the project for which the VPC is being created"
  type = object({
    name       = string
    short_name = string
    version    = string
    team       = string
    url        = string
  })
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 Bucket to store state files for terraform"
  default     = "terraform-statefiles"
}

# variables.tf

variable "cpu_scaling_config" {
  description = "Configuration for CPU-based auto-scaling of the ECS service"
  type = object({
    enabled             = bool
    threshold           = number
    evaluation_periods  = number
    period              = number
    scale_up_cooldown   = number
    scale_down_cooldown = number
    scale_up_steps = list(object({
      lower_bound = number
      upper_bound = number
      adjustment  = number
    }))
    scale_down_steps = list(object({
      lower_bound = number
      upper_bound = number
      adjustment  = number
    }))
  })
  default = null
}

variable "memory_scaling_config" {
  description = "Configuration for memory-based auto-scaling of the ECS service"
  type = object({
    enabled             = bool
    threshold           = number
    evaluation_periods  = number
    period              = number
    scale_up_cooldown   = number
    scale_down_cooldown = number
    scale_up_steps = list(object({
      lower_bound = number
      upper_bound = number
      adjustment  = number
    }))
    scale_down_steps = list(object({
      lower_bound = number
      upper_bound = number
      adjustment  = number
    }))
  })
  default = null
}

variable "request_scaling_config" {
  description = "Configuration for request count-based auto-scaling of the ECS service"
  type = object({
    enabled             = bool   # Whether request count scaling is enabled
    threshold           = number # Request count per target threshold for scaling down
    evaluation_periods  = number # Number of periods to evaluate the metric
    period              = number # Length of each evaluation period in seconds
    scale_up_cooldown   = number # Cooldown period in seconds for scale-up
    scale_down_cooldown = number # Cooldown period in seconds for scale-down
    scale_up_steps = list(object({
      lower_bound = number # Lower bound relative to scale_up_threshold (e.g., 0)
      upper_bound = number # Upper bound relative to scale_up_threshold (null for no upper limit)
      adjustment  = number # Number of tasks to add
    }))
    scale_down_steps = list(object({
      lower_bound = number # Lower bound relative to scale_down_threshold (null for no lower limit)
      upper_bound = number # Upper bound relative to scale_down_threshold (e.g., 0)
      adjustment  = number # Number of tasks to remove (typically negative)
    }))
  })
  default = null
}
