module "vpc" {
  source = "../vpc"

  prefix                     = var.prefix
  aws_region                 = var.aws_region
  tags                       = var.tags
  vpc_cidr_block             = "10.0.0.0/16"
  public_availability_zones  = ["ap-northeast-1a", "ap-northeast-1c"]
  private_availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
  need_nat_gateway           = false
}
