variable "app_name" {
  description = "Name of the app - no spaces - alphanumeric, hyphens, underscores OK"
  default = "ts-vue"
}

variable "frontend_domain_name" {
  description = "The fully qualified domain name (FQDN) for the frontend application"
  default = "ts-vue.rymcg.tech"
}

variable "aws_region" {
    description = "AWS region to use by default"
    default = "us-east-1"
}

variable "aws_public_html_bucket" {
  description = "AWS S3 bucket to store static build of the frontend HTML assets."
  default = "ec-ts-vue-html"
}

variable "aws_logs_bucket" {
  description = "AWS S3 bucket to store logs"
  default = "ec-ts-vue-logs"
}

variable "aws_chalice_deploy_bucket" {
  description = "AWS S3 bucket to store chalice deployment packages"
  default = "ec-chalice-deploy"
}

variable "aws_route53_zone" {
  description = "AWS Route53 domain zone name (assumed preexisting)"
  default = "rymcg.tech"
}

variable "cognito_auth_domain" {
    description = "AWS Cognito auth domain. Pick a UNIQUE name (per avail zone)."
    default = "ts-vue"
}

