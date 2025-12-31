data "aws_region" "current" {}

# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${lookup(var.project_meta, "short_name")},${var.deployment_environment},vpc-endpoints-sg"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("-", [
      lookup(var.project_meta, "short_name"),
      var.deployment_environment,
      "vpc-endpoints-sg"
      ]
    )
  }

}


resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.primary.id
  service_name       = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = join("-", [
      lookup(var.project_meta, "short_name"),
      var.deployment_environment,
      "ecr-api-endpoint"
      ]
    )
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.primary.id
  service_name       = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  tags = {
    Name = join("-", [
      lookup(var.project_meta, "short_name"),
      var.deployment_environment,
      "ecr-dkr-endpoint"
      ]
    )
  }

}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.primary.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = join("-", [
      lookup(var.project_meta, "short_name"),
      var.deployment_environment,
      "s3-gw-endpoint"
      ]
    )
  }
}


# Attach endpoint to route tables
resource "aws_vpc_endpoint_route_table_association" "s3_gateway_association" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
}

locals {
  eice_subnet_id = values(aws_subnet.private)[0].id
}

resource "aws_ec2_instance_connect_endpoint" "ec2_connect_ep" {
  subnet_id          = local.eice_subnet_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = join("-", [
      lookup(var.project_meta, "short_name"),
      var.deployment_environment,
      "ec2-connect-ep"
    ])
  }
}

# modules/vpc_endpoints/outputs.tf
output "ecr_api_endpoint_id" {
  value = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  value = aws_vpc_endpoint.ecr_dkr.id
}

output "s3_gateway_endpoint_id" {
  value = aws_vpc_endpoint.s3_gateway.id
}

output "ec2_instance_connect_endpoint_id" {
  value = aws_ec2_instance_connect_endpoint.ec2_connect_ep.id
}
