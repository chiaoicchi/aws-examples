module "sub_domain" {
  source = "../subdomain-phz/sub-phz"

  aws_region             = var.aws_region
  aws_parent_phz_region  = var.aws_region
  tags                   = var.tags
  parent_domain          = var.parent_domain
  sub_domain             = var.sub_domain
  cross_account_role_arn = var.parent_domain_cross_account_role_arn
}

resource "aws_route53_record" "cloudfront" {
  zone_id         = module.sub_domain.sub_domain_zone_id
  name            = var.sub_domain
  type            = "A"
  allow_overwrite = true
  alias {
    name                    = aws_cloudfront_distribution.this.domain_name
    zone_id                 = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wildcard_cloudfront" {
  zone_id         = module.sub_domain.sub_domain_zone_id
  name            = "*.${var.sub_domain}"
  type            = "A"
  allow_overwrite = true
  alias {
    name                    = aws_cloudfront_distribution.this.domain_name
    zone_id                 = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cloudfront_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = module.sub_domain.sub_domain_zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
}

resource "aws_route53_zone" "private" {
  name = var.sub_domain
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "alb" {
  zone_id         = aws_route53_zone.private.zone_id
  name            = var.sub_domain
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wildcard_alb" {
  zone_id         = aws_route53_zone.private.zone_id
  name            = "*.${var.sub_domain}"
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.private.zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
}
