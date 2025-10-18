# ----------
# backend.tf の設定
# ----------
remote_state {
  backend = "s3"

  generate = {
    path = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "terragrunt-${local.env}-${local.name}-terraform-tfstate-s3-bucket"
    key = "${path_relative_to_include()}/terraform.tfstate"
    region = "${local.region}"
    encrypt = true
    bucket_sse_algorithm = "AES256"
    dynamodb_table = "terragrunt-${local.env}-${local.name}-terraform-tfstate-lock"

    s3_bucket_tags = {
      "Environments" = "${path_relative_to_include()}"
      "ServiceName" = "${local.name}"
      "CreatedByTerragrunt" = "true"
    }
  }
}

# ----------
# provider の設定
# ----------
generate "provider" {
  path = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
    provider "aws" {
      region = "${local.region}"
      default_tags {
        tags = {
          Environments = "${local.env}"
          ServiceName = "${local.name}"
          ManagedByTerraform = true
        }
      }
    }
  EOF
}

# ----------
# terraform の設定
# ----------
generate "version" {
  path = "_terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
    terraform {
      required_version = "~> 1.10.0"
      required_providers {
        aws = {
          version = "~> 5.87.0"
          source = "hashicorp/aws"
        }
        archive = {
          version = "~> 2.0"
          source = "hashicorp/archive"
        }
      }
    }
  EOF
}

# ----------
# local 変数
# ----------
locals {
  env_vars = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  env = local.env_vars.env
  region = local.common_vars.region
  name = local.common_vars.name
}
