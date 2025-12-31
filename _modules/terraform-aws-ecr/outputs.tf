# keep the repository key from for_each as the map key
output "ecr_repos_map_by_key" {
  value       = { for key, repo in aws_ecr_repository.private_repo : key => repo.repository_url }
  description = "List of ECR repository names created."
}
