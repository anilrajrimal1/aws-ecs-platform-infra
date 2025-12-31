#VARIABLES
variable "project_meta" {
  description = "Metadata relating to the project for which the database is being created"
  type = object({
    name        = string
    environment = string
    team        = string
  })
}


#VARIABLES

variable "ecr_repos" {
  type = map(object({
    name        = string
    description = string
  }))
  description = "Map of ECR repositories to create, with their names and descriptions."
  default     = {}

}

variable "lifecycle_policy" {
  type        = string
  description = "value of the lifecycle policy for ECR repositories in JSON format"
  default     = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Save 3 copies of tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["h-", "master", "main", "develop", "staging"],
          "countType": "imageCountMoreThan",
          "countNumber": 10
        },
        "action": {
          "type": "expire"
        }
      },
      {
        "rulePriority": 2,
        "description": "Delete all untagged images",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      },
      {
        "rulePriority": 3,
        "description": "Delete all other tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPatternList": ["*"],
          "countType": "imageCountMoreThan",
          "countNumber": 3
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF

}
