resource "aws_acm_certificate" "alb" {
  domain_name       = var.sub_domain
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_certif : record.fqdn]
}

resource "aws_acm_certificate" "cognito" {
  count = var.need_authenticate ? 1 : 0

  provider = aws.virginia

  domain_name       = "auth.${var.sub_domain}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cognito" {
  count = var.need_authenticate ? 1 : 0

  provider = aws.virginia

  certificate_arn         = aws_acm_certificate.cognito[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cognito_certif : record.fqdn]
}
