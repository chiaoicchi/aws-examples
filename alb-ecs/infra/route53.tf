module "sub_domain" {
  source = "../../subdomain-phz/sub-phz"

  aws_region             = var.aws_region
  aws_parent_phz_region  = var.aws_region
  tags                   = var.tags
  parent_domain          = var.parent_domain
  sub_domain             = var.sub_domain
  cross_account_role_arn = var.parent_domain_cross_account_role_arn
}

resource "aws_route53_record" "alb" {
  zone_id = module.sub_domain.sub_domain_zone_id
  name    = module.sub_domain.sub_domain_zone_name
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alb_certif" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  zone_id         = module.sub_domain.sub_domain_zone_id
  ttl             = 60
}

resource "aws_route53_record" "cognito" {
  count = var.need_authenticate ? 1 : 0

  zone_id = module.sub_domain.sub_domain_zone_id
  name    = "auth.${module.sub_domain.sub_domain_zone_name}"
  type    = "A"
  alias {
    name                   = aws_cognito_user_pool_domain.this[0].cloudfront_distribution
    zone_id                = aws_cognito_user_pool_domain.this[0].cloudfront_distribution_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cognito_certif" {
  for_each = var.need_authenticate ? {
    for dvo in aws_acm_certificate.cognito[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  zone_id         = module.sub_domain.sub_domain_zone_id
  ttl             = 60
}
