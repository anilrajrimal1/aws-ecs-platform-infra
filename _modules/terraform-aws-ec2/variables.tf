#VARIABLES
variable "project_meta" {
  description = "Metadata relating to the project for which the database is being created"
  type = object({
    name        = string
    environment = string
    team        = string
  })
}

variable "ec2_instance_name" {
  type    = string
  default = null
}


variable "vpc_id" {
  type = string
}

variable "ec2_instance_ami" {
  type    = string
  default = "ami-084568db4383264d4"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

variable "create_n_attach_ec2_iam_instance_profile" {
  type    = bool
  default = false
}

variable "ec2_instance_profile_policy_statements" {
  type = list(object({
    sid       = string
    effect    = string
    resources = list(string)
    actions   = list(string)
  }))

}

variable "ec2_iam_instance_profile" {
  type    = string
  default = ""
}

variable "create_ssh_key_pair" {
  type    = bool
  default = false
}

variable "ssh_private_key_store_path" {
  type    = string
  default = ""
}

variable "existing_ssh_key_pair_name" {
  type    = string
  default = ""
}

variable "ec2_subnet_id" {
  type = string
}

variable "create_sec_grp" {
  type    = bool
  default = true
}

variable "ec2_sec_grps" {
  description = "List of security group IDs to assign to the EC2 instance"
  type        = list(string)
  default     = []
}

variable "ec2_root_vol_size" {
  type    = string
  default = "15"
}

variable "ec2_ebs_volumes" {
  type = list(object({
    size     = number
    type     = string
    device   = string
    vol_name = string
  }))

  default = [
    {
      size     = 20
      type     = "gp2"
      device   = "/dev/sdb"
      vol_name = "docker-volume"
    },
    {
      size     = 30
      type     = "gp2"
      device   = "/dev/sdc"
      vol_name = "project-volume"
    }
  ]
}

variable "ec2_sec_grp_ingress" {
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
  }))

  default = [
    {
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
  ]
}

variable "ec2_sec_grp_egress" {
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
  }))

  default = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
}

variable "ec2_user_data" {
  description = "EC2 User data script"
  type        = string
  default     = null
}

variable "create_eip" {
  type    = bool
  default = false
}
