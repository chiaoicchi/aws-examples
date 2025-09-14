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
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
