# Terraform AWS ECS Module

An opinionated Terraform module for AWS ECS.

This module helps deploy the following AWS resources

- TBD

Planned to be implemented:

- TBD

## How to use

:warning: Please note that this module compatible with AWS provider version >= 5.0.0. Tested with v5.1.0;

1. Import the module in your root module:

```
module "ecs" {
  source = "git::https://gitlab.com/eternaltyro/terraform-aws-ecs.git"

  ...
  key = var.value
}
```

If you wish to use SSH to connect to git, then something like this will help:

```
module "ecs" {
  source = "git::ssh://username@gitlab.com/eternaltyro/terraform-aws-ecs.git"
}
```

2. Write a provider block with the official AWS provider:

```
terraform {
  required_version = ">= 1.4.0"

  requried_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }
}

provider "aws" {
  region = lookup(var.aws_region, var.deployment_environment)

  default_tags {
    tags = var.resource_tags
  }
}
```

3. Initialise the backend, and plan

```
$ terraform init
$ terraform plan
```

## Outputs

- TBD

## Variables

- TBD

## References

[ref1]: TBD

## Copyright and License texts

The project is licensed under GNU LGPL. Please make any modifications to this module public. Read LICENSE, COPYING.LESSER, and COPYING files for license text

Copyright (C) 2023 eternaltyro
This file is part of Terraform AWS VPC Module aka terraform-aws-vpc project

terraform-aws-vpc is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License.

terraform-aws-vpc is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

License text can be found in the repository
