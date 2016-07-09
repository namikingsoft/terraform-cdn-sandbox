variable "name" {
  default = {
    prd  = "terraform-cdn-sandbox-production"
    stg  = "terraform-cdn-sandbox-staging"
    dev  = "terraform-cdn-sandbox"
  }
  description = "this infrastructure name"
}

variable "env"         { default = "dev" }
variable "acl"         { default = "public-read" }
variable "policy_file" { default = "policy.json.tpl" }
variable "index"       { default = "index.html" }
#variable "aws_region"     {}
#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "fastly_api_key" {}
