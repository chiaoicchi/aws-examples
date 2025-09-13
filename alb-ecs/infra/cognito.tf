resource "aws_cognito_user_pool" "this" {
  count = var.need_authenticate ? 1 : 0

  name = "${var.prefix}-user-pool"
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }
  auto_verified_attributes = ["email"]
  alias_attributes         = ["email"]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_message = "Dear {username}\nYour tempolary password is {####}. You need to change password after first login."
      email_subject = "$invite to ${var.prefix}"
      sms_message   = "Dear {username}\nYour tempolary password is {####}. You need to change password after first login."
    }
  }
  tags = local.tags
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.need_authenticate ? 1 : 0

  domain          = "auth.${var.sub_domain}"
  certificate_arn = aws_acm_certificate.cognito[0].arn
  user_pool_id    = aws_cognito_user_pool.this[0].id
  depends_on      = [aws_route53_record.alb, aws_acm_certificate_validation.cognito]
}

resource "aws_cognito_user_pool_client" "this" {
  count = var.need_authenticate ? 1 : 0

  name          = "${var.prefix}-user-pool-client"
  user_pool_id  = aws_cognito_user_pool.this[0].id
  callback_urls = ["https://${var.sub_domain}/oauth2/idpresponse"]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user" "defaults" {
  for_each = var.need_authenticate ? var.default_users : {}

  user_pool_id = aws_cognito_user_pool.this[0].id
  username     = each.key
  attributes = {
    email          = each.value.email
    email_verified = "true"
  }
  temporary_password = each.value.password
}
