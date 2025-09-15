resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = var.sub_domain
    origin_id   = aws_lb.this.id
    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.this.id
    }
  }
  enabled = true
  aliases = ["${var.sub_domain}", "*.${var.sub_domain}"]
  default_cache_behavior {
    allowed_methods          = ["HEAD", "GET"]
    cached_methods            = ["HEAD", "GET"]
    target_origin_id         = aws_lb.this.id
    viewer_protocol_policy   = "https-only"
    min_ttl                  = 0
    default_ttl              = 60
    max_ttl                  = 60
    cache_policy_id          = aws_cloudfront_cache_policy.this.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.this.id
  }
  restrictions {
    geo_restriction {
      locations        = ["JP"]
      restriction_type = "whitelist"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.cloudfront.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_request_policy" "this" {
  name = "${var.prefix}-origin-request-policy"
  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
}

resource "aws_cloudfront_cache_policy" "this" {
  name = "${var.prefix}-cache-policy"
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host"]
      }
    }
  }
}

resource "aws_cloudfront_vpc_origin" "this" {
  vpc_origin_endpoint_config {
    name                   = "${var.prefix}-vpc-origin"
    arn                    = aws_lb.this.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

resource "null_resource" "cloudfront_update_trigger" {
  triggers = {
    cloudfront_id = aws_cloudfront_distribution.this.id
  }
  depends_on = [aws_cloudfront_distribution.this, aws_cloudfront_vpc_origin.this]
}

data "aws_security_group" "vpc_origin" {
  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  depends_on = [null_resource.cloudfront_update_trigger]
}

