resource "random_pet" "db" {
}

locals {
  ec2_identifier = var.ec2_instance_name != null ? var.ec2_instance_name : join("-", [
    lookup(var.project_meta, "name"),
    lookup(var.project_meta, "environment"),
    lookup(var.project_meta, "team"),
    "ec2",
    random_pet.db.id
    ]
  )
}
