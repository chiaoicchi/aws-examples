terraform {
  required_version = ">=1.12.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0, <7.0.0"
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

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

locals {
  tags = merge(
    var.tags,
    {
      "Prefix" = var.prefix,
    }
  )
}
