variable "name"        { default = "terraform-cdn-sandbox" }
variable "acl"         { default = "public-read" }
variable "policy_file" { default = "policy.json.tpl" }
variable "index"       { default = "index.html" }
#variable "aws_region"     {}
#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "fastly_api_key" {}

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
    bucket_name = "${var.name}"
  }
}

resource "aws_s3_bucket" "origin" {
  bucket = "${var.name}"
  acl    = "${var.acl}"
  policy = "${template_file.s3_policy.rendered}"

  website {
    index_document = "${var.index}"
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "${concat(aws_s3_bucket.origin.id, ".s3.amazonaws.com")}"
    origin_id   = "${var.name}"
  }

  enabled             = true
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
  name = "${var.name}"

  domain {
    name    = "${concat(aws_s3_bucket.origin.id, ".global.ssl.fastly.net")}"
    comment = "Free Shared TLS"
  }

  backend {
    address = "${aws_s3_bucket.origin.website_endpoint}"
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

  default_host = "${aws_s3_bucket.origin.website_endpoint}"
}
