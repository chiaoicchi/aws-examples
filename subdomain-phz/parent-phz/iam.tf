resource "aws_iam_role" "cross_account" {
  name = "${var.sub_domain}-cross-account-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.sub_phz_account_id}:root"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "route53_access" {
  name = "${var.sub_domain}-route53-access-policy"
  role = aws_iam_role.cross_account.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
        ]
        Effect   = "Allow"
        Resource = data.aws_route53_zone.parent_zone.arn
      },
      {
        Action = [
          "route53:ListHostedZones",
          "route53:ListTagsForResource",
          "route53:GetChange",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
