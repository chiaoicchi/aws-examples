resource "aws_cloudtrail" "this" {
  name = "${var.prefix}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.this.id
  tags = local.tags
  depends_on = [aws_s3_bucket_policy.this]
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-cloudtrail-logs"
  force_destroy = var.delete_s3
  tags = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    id = "expiration"
    filter {}
    expiration {
      days = 10
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = aws_s3_bucket.this.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.prefix}-cloudtrail"
          }
        }
      },
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.this.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control",
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.prefix}-cloudtrail"
          }
        }
      }
    ]
  })
}
