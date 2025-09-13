module "vpc" {
  source = "../../vpc"

  prefix     = var.prefix
  aws_region = var.aws_region
  tags       = var.tags

  vpc_cidr_block             = "10.0.0.0/16"
  public_availability_zones  = ["ap-northeast-1a", "ap-northeast-1c"]
  private_availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
  need_nat_gateway           = var.use_nat_gateway
}

resource "aws_vpc_endpoint" "s3" {
  count = var.use_nat_gateway ? 0 : 1

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids   = [module.vpc.private_route_table_id]
  vpc_endpoint_type = "Gateway"
  tags              = local.tags
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.use_nat_gateway ? toset([]) : toset(
    concat(
      [
        "ecr.api",
        "ecr.dkr",
        "logs",
        "sts",
      ],
      var.enable_execute_command ? [
        "ssm",
        "ssmmessages",
        "ec2messages",
      ] : []
    )
  )

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_security_group" "vpc_endpoint" {
  count = var.use_nat_gateway ? 0 : 1

  name   = "${var.prefix}-vpc-endpoint-sg"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_from_alb" {
  count = var.use_nat_gateway ? 0 : 1

  security_group_id            = aws_security_group.vpc_endpoint[0].id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_from_ecs" {
  count = var.use_nat_gateway ? 0 : 1

  security_group_id            = aws_security_group.vpc_endpoint[0].id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint" {
  count = var.use_nat_gateway ? 0 : 1

  security_group_id = aws_security_group.vpc_endpoint[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
