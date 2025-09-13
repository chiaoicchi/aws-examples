resource "aws_lb" "this" {
  name                       = "${var.prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false
  subnets                    = module.vpc.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }
  tags = local.tags
}

resource "aws_security_group" "alb" {
  name   = "${var.prefix}-alb-sg"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.https_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.http_cidr_block
}

resource "aws_vpc_security_group_egress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  # TODO!: limit to cognito security group, but this is impossible.
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_http" {
  security_group_id            = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.alb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = 404
    }
  }
  tags       = local.tags
  depends_on = [aws_acm_certificate_validation.alb]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "http" {
  name                 = "${var.prefix}-tg"
  target_type          = "ip"
  vpc_id               = module.vpc.vpc_id
  port                 = var.app_port
  protocol             = "HTTP"
  deregistration_delay = 300
  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  depends_on = [aws_lb.this]
}

resource "aws_lb_listener_rule" "http" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  dynamic "action" {
    for_each = var.need_authenticate ? [0] : []
    content {
      type = "authenticate-cognito"
      authenticate_cognito {
        scope               = "openid"
        user_pool_arn       = aws_cognito_user_pool.this[0].arn
        user_pool_client_id = aws_cognito_user_pool_client.this[0].id
        user_pool_domain    = aws_cognito_user_pool_domain.this[0].domain
      }
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.prefix}-alb-logs"
  force_destroy = var.delete_alb_logs_bucket
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*",
        ]
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
      }
    ]
  })
}
