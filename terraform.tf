provider "aws" {
  #region     = "${var.aws_region}"
  #access_key = "${var.aws_access_key}"
  #secret_key = "${var.aws_secret_key}"
}

provider "fastly" {
  #api_key    = "${var.fastly_api_key}"
}


resource "template_file" "s3_policy" {
  template = "${file(concat(path.module, "/", var.policy_file))}"

  vars {
    bucket_name = "${lookup(var.name, var.env)}"
  }
}

resource "aws_s3_bucket" "origin" {
  bucket = "${lookup(var.name, var.env)}"
  acl    = "${var.acl}"
  policy = "${template_file.s3_policy.rendered}"
  force_destroy = true
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "${aws_s3_bucket.origin.id}.s3.amazonaws.com"
    origin_id   = "${lookup(var.name, var.env)}"
  }

  enabled             = true
  retain_on_delete    = true
  comment             = "Terraform CDN Sandbox CloudFront"
  default_root_object = "${var.index}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.origin.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "JP"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "fastly_service_v1" "cdn" {
  name = "${lookup(var.name, var.env)}"

  domain {
    name    = "${aws_s3_bucket.origin.id}.global.ssl.fastly.net"
    comment = "Free Shared TLS"
  }

  backend {
    address = "${aws_s3_bucket.origin.id}.s3.amazonaws.com"
    name    = "AWS S3 hosting"
    port    = 80
  }

  gzip {
    name          = "Default Gzip Rule"
    extensions    = ["css", "js", "html", "eot", "ico", "otf", "ttf", "json"]
    content_types = [
      "text/html", "application/x-javascript", "text/css",
      "application/javascript", "text/javascript", "application/json",
      "application/vnd.ms-fontobject", "application/x-font-opentype",
      "application/x-font-truetype", "application/x-font-ttf", "application/xml",
      "font/eot", "font/opentype", "font/otf", "image/svg+xml",
      "image/vnd.microsoft.icon", "text/plain", "text/xml"
    ]
  }

  default_host = "${aws_s3_bucket.origin.id}.s3.amazonaws.com"
  default_ttl  = 86400

  force_destroy = true
}
