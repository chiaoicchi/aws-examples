output "app_url" {
  value = aws_route53_record.alb.name
}
