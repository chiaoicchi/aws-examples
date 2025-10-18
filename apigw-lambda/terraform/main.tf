terraform {
  required_version = ">=1.13.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0, <7.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">2.7.0, <3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">3.2.0, <4.0.0"
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
