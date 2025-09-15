resource "aws_lb" "this" {
  name               = "${var.prefix}-alb"
  load_balancer_type = "application"
  internal           = true
  idle_timeout       = 60
  subnets            = module.vpc.private_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_security_group" "alb" {
  name   = "${var.prefix}-alb-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_vpc_origin" {
  security_group_id            = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.vpc_origin.id
  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [null_resource.cloudfront_update_trigger]
  }
  depends_on = [null_resource.cloudfront_update_trigger, data.aws_security_group.vpc_origin]
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
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
  depends_on = [aws_acm_certificate_validation.alb]
}

resource "aws_lb_listener_rule" "a" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "This is A"
      status_code  = 200
    }
  }
  condition {
    host_header {
      values = ["a.${var.sub_domain}"]
    }
  }
}

resource "aws_lb_listener_rule" "b" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "This is B"
      status_code  = 200
    }
  }
  condition {
    host_header {
      values = ["b.${var.sub_domain}"]
    }
  }
}


