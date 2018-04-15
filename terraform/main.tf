// AWS infrastructure for hosting a single page app and backend resources
// - S3 bucket to store the website files (SPA)
// - Cloudfront for public content delivery
// - Route53 for DNS with a custom domain name
// - ACM issued TLS certificate
// - API Gateway and Lambda serverless backend
// - Cognito User Pool authentication

// Prerequisites:
// - Configured AWS cli with permissive IAM role (you just need ~/.aws/credentials created):
//  - 
// - Preconfigured Route53 zone for your domain, do this in the AWS console first.
// - Preconfigured Certificate in AWS Certificate Manager, do this in the AWS console first.
// - Update vars.ts with the names of those resources you created.
// - Create these with CLI or web console first.
// - Reading through this source and understanding what it does :)
// - Edit all the variable defaults in vars.tf before applying this.

// Notes:
// If you haven't used CloudFront before, you may be unaccustomed to how long it takes to create a distribution.
// Terraform itself does not take long to run, but you should open up the AWS console in your browser,
// navigate to the Cloudfront Distributions page and watch the deployment going on in the background.
// It will stay in "In Progress" status until it's ready to be viewed.
// Initial CloudFront deployment might take 30 minutes to an hour,
// depending on how many edge nodes it has to configure for the set price class.

provider "aws" {
    region = "${var.aws_region}"
}

// TLS certificate - a reference to a certificate already created in AWS Certificate Manager:

data "aws_acm_certificate" "certificate" {
  domain = "${var.aws_certificate_domain}"
  statuses = ["ISSUED"]
  most_recent = true
}

// Route53 zone - Create this in the console manually

data "aws_route53_zone" "zone" {
  name = "${var.aws_route53_zone}"
}


// Cloudfront access identity to read from the S3 bucket:
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Managed by ${var.app_name} terraform"
}

// S3 Policy to only give permission to the cloudfront access identity:
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

// Create the S3 bucket to store the HTML, images, javascript etc for the SPA:
resource "aws_s3_bucket" "public_html" {
  bucket = "${var.aws_public_html_bucket}"
  // Attach the cloudfront S3 policy created above:
  policy = "${data.aws_iam_policy_document.cloudfront_s3_policy.json}"
  website {
    index_document = "index.html"
  }
}

// Create an S3 bucket for cloudfront (or anything else) to store their logs:
resource "aws_s3_bucket" "logs" {
  bucket = "${var.aws_logs_bucket}"
}

// Configure cloudfront as the CDN serving content from the S3 bucket
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
    acm_certificate_arn = "${data.aws_acm_certificate.certificate.arn}"
    ssl_support_method = "sni-only"
  }

}

resource "aws_route53_record" "domain" {
  zone_id = "${data.aws_route53_zone.zone.id}"
  name = "${var.frontend_domain_name}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}

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


