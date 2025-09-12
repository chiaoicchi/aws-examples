data "aws_route53_zone" "parent" {
  provider = aws.parent

  name         = var.parent_domain
  private_zone = false
}

resource "aws_route53_zone" "sub" {
  name = var.sub_domain
  tags = var.tags
}

resource "aws_route53_record" "delegate_ns" {
  provider = aws.parent

  zone_id = data.aws_route53_zone.parent.zone_id
  name    = var.sub_domain
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.sub.name_servers
}
