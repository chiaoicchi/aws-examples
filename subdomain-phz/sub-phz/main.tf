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

provider "aws" {
  alias  = "parent"
  region = var.aws_parent_phz_region
  assume_role {
    role_arn = var.cross_account_role_arn
  }
}

