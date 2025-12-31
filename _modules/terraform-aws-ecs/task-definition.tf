resource "aws_ecs_task_definition" "main" {
  family                   = lookup(var.container_settings, "service_name")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = lookup(var.container_capacity, "cpu")
  memory                   = lookup(var.container_capacity, "memory_mb")

  ephemeral_storage {
    size_in_gib = var.container_ephemeral_storage
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.container_cpu_architecture
  }

  dynamic "volume" {
    for_each = var.efs_mounts
    content {
      name = volume.value.name

      efs_volume_configuration {
        file_system_id     = volume.value.efs_file_system_id
        transit_encryption = volume.value.efs_transit_encryption

        authorization_config {
          access_point_id = volume.value.efs_access_point_id
          iam             = volume.value.efs_iam_authz
        }
      }
    }
  }


  container_definitions = jsonencode([
    {
      name = lookup(var.container_settings, "service_name")

      image = join(":", [
        lookup(var.container_settings, "image_url"),
        lookup(var.container_settings, "image_tag")
      ])
      command = var.container_commands

      privileged = lookup(var.container_security, "privileged")

      cpu       = lookup(var.container_capacity, "cpu")
      memory    = lookup(var.container_capacity, "memory_mb")
      essential = true

      portMappings = [
        {
          containerPort = lookup(var.container_settings, "app_port")
          hostPort      = lookup(var.container_settings, "app_port")
          protocol      = var.app_port_protocol
        },
      ]

      environment      = [for k, v in var.container_envvars : { name = k, value = v }]
      environmentFiles = [for c_envfile in var.container_envfiles : { type = c_envfile.type, value = c_envfile.value }]
      secrets = [
        for secret in var.container_secrets : {
          name      = secret.name
          valueFrom = secret.valueFrom # This will take the value from the input directly
        }
      ]

      mountPoints = [
        for mount in var.efs_mounts : {
          sourceVolume  = mount.name
          containerPath = mount.container_path
          readOnly      = mount.read_only
        }
      ]

      # linuxParameters = {
      #   capabilities = var.linux_capabilities
      # }

      logConfiguration = {
        logdriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = var.log_configuration.options.awslogs-region
          awslogs-stream-prefix = var.log_configuration.options.awslogs-stream-prefix
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecs-agent.arn
  task_role_arn      = var.task_role_arn
}
