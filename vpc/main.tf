terraform {
  required_version = ">=1.12.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0, <7.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = merge(
    var.tags,
    {
      "Prefix" = var.prefix,
    }
  )
  subnet_cidr_blocks = {
    public = {
      for i, v in var.public_availability_zones :
      v => cidrsubnet(var.vpc_cidr_block, var.subnet_cidr_block_newbit, i)
    }
    private = {
      for i, v in var.private_availability_zones :
      v => cidrsubnet(var.vpc_cidr_block, var.subnet_cidr_block_newbit, i + length(var.public_availability_zones))
    }
  }
}
