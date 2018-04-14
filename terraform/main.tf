provider "aws" {
    region = "${var.aws_region}"
}

// Public S3 bucket to hold our SPA html web assets:

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Managed by ${var.app_name} terraform"
}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.aws_public_html_bucket}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.aws_public_html_bucket}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket" "public_html" {
  bucket = "${var.aws_public_html_bucket}"
  policy = "${data.aws_iam_policy_document.cloudfront_s3_policy.json}"
  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.aws_logs_bucket}"
}

// Cloudfront to serve our s3 bucket to the world:

resource "aws_cloudfront_distribution" "s3_distribution" {
  price_class = "PriceClass_100"
  origin {
    domain_name = "${aws_s3_bucket.public_html.bucket_domain_name}"
    origin_id = "s3_origin"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  is_ipv6_enabled = true
  comment = "Managed by ${var.app_name} terraform"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket = "${aws_s3_bucket.logs.bucket_domain_name}"
    prefix = "${var.app_name}"
  }

  aliases = ["${var.frontend_domain_name}"]

  default_cache_behavior {
    allowed_methods = ["GET","HEAD","OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "s3_origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

// Route53 domain routing

# resource "aws_route53_record" "domain" {
#   zone_id = "${var.aws_route53_zone}"
#   name = "${var.app_name}-www"
#   type = "A"

#   alias {
#     name = "${aws_s3_bucket.public_html.website_domain}"
#     zone_id = "${aws_s3_bucket.public_html.hosted_zone_id}"
#   }
# }

// Cognito User Pool provides our backend authentication system:

resource "aws_cognito_user_pool" "pool" {
  name = "ts_vue_pool"
  auto_verified_attributes = [
    "email"
  ]
}

resource "aws_cognito_user_pool_client" "client" {
  name = "ts_vue_client"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
  supported_identity_providers = ["COGNITO"]
  callback_urls = ["http://localhost:8080"]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["phone","email","openid","aws.cognito.signin.user.admin","profile"]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain = "${var.cognito_auth_domain}"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
}


