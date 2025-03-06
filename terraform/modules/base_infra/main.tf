locals {
  default_tags = {project = "cf-demo"}
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "demo_static_content_bucket" {
  bucket = "${var.bucket-name}"
  tags = local.default_tags
}

resource "aws_cloudfront_origin_access_control" "my_oac" {
  name            = aws_s3_bucket.demo_static_content_bucket.bucket_regional_domain_name
  description     = "Access control for my CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"  # Control how to sign requests (e.g., "always" for signed URLs)
  signing_protocol = "sigv4"   # Use Signature Version 4 for signing requests
}

resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name            = aws_s3_bucket.demo_static_content_bucket.bucket_regional_domain_name
    origin_id              = aws_s3_bucket.demo_static_content_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.my_oac.id
  }

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id       = aws_s3_bucket.demo_static_content_bucket.bucket
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  default_root_object = "index.html"
  price_class = "PriceClass_100"
}

resource "aws_s3_bucket_policy" "demo_static_content_bucket_policy" {
  bucket = aws_s3_bucket.demo_static_content_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid: "AllowCloudFrontServicePrincipal",
        Effect: "Allow",
        Principal: {
          Service: "cloudfront.amazonaws.com"
        },
        Action: "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.demo_static_content_bucket.bucket}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.my_distribution.id}"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}


