output "cluster_arn" {
  value       = aws_ecs_service.main.cluster
  description = "Cluster ARN associated to the service"
}

output "desired_count" {
  value       = aws_ecs_service.main.desired_count
  description = "Number of instances of the task definition"
}

output "service_arn" {
  value       = aws_ecs_service.main.id
  description = "ARN that identifies the service"
}

output "service_name" {
  value       = aws_ecs_service.main.name
  description = "Name of the service"
}

output "task_definition" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}