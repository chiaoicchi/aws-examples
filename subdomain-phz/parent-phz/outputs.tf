output "aws_parent_phz_region" {
  value = var.aws_region
}

output "cross_account_role_arn" {
  value = aws_iam_role.cross_account.arn
}
