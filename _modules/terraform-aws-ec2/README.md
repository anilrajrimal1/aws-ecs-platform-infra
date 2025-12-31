# EC2 module

### Resources

Creates Ec2 Instances

### Roadmap

- Basic ec2 (create ssh key and save to devops bucket)
- add SSM login/Shell Access (optional iam creation / assign sent user arns)

### Usage

```hcl

module "ec2" {

  source                   = "git::https://github.com/hotosm/terraform-aws-ec2.git?ref=main"
  project_meta              = var.project_meta
  vpc_id                   = var.ec2_vpc_id
  ec2_subnet_id            = var.ec2_subnet_id
  create_ssh_key_pair      = var.create_ssh_key_pair
  ec2_iam_instance_profile = var.ec2_iam_instance_profile
  ec2_root_vol_size        = var.ec2_root_vol_size
  ec2_ebs_volumes          = var.ec2_ebs_volumes
  ec2_sec_grp_ingress      = var.ec2_sec_grp_ingress
  ec2_sec_grp_egress       = var.ec2_sec_grp_egress
}

```
