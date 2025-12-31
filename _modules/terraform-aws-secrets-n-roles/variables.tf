variable "org_meta" {
  description = "Org info for secrets manager prefix"
  type        = map(string)
}

variable "project_meta" {
  description = "Metadata relating to the project for which the database is being created"
  type = object({
    name       = string
    short_name = string
    team       = string
    version    = string
    url        = string
  })
}



variable "s3_bucket_name" {
  type        = string
  description = "S3 Bucket to store state files for terraform"
  default     = "terraform-statefiles"
}

variable "deployment_environment" {
  description = "Deployment flavour or variant identified by this name"
  type        = string

  default = "dev"
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
