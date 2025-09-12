data "aws_route53_zone" "parent_zone" {
  name         = var.parent_domain
  private_zone = false
}
