resource "aws_acm_certificate" "cloudfront" {
  provider = aws.virginia

  domain_name               = "*.${var.sub_domain}"
  subject_alternative_names = [var.sub_domain]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.virginia

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}

resource "aws_acm_certificate" "alb" {
  domain_name               = "*.${var.sub_domain}"
  subject_alternative_names = [var.sub_domain]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_validation : record.fqdn]
}
