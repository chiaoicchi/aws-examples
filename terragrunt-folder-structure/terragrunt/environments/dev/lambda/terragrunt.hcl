include "root" {
  path = find_in_parent_folders("root.hcl")
}

# ----------
# main.tf の設定
# ----------
terraform {
  source = "../../../modules/lambda"
}

# ----------
# variable の設定
# ----------
inputs = {
  env = local.env
  name = local.name
}

# ----------
# local 変数
# ----------
locals {
  env_vars = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  env = local.env_vars.env
  name = local.common_vars.name
}
