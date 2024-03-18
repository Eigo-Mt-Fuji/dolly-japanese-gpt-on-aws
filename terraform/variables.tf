variable "backend_deploy_s3_bucket_name" {
  default = "deploy-047980477351-ap-northeast-1-efg.river"
}

variable "backend_allow_origin_url" {
  default = "https://efgriver.com"
}

variable "app_deployed_at" {
  default = "20221206175700"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:047980477351:certificate/9
1defbde-5ced-4c62-b817-c4390fa4cbf7"
}
variable "rest_api_domain_name" {
  default = "ml-api.efgriver.com"
}
variable "route53_zone_id" {
 default = "Z08256261BDETXBUSKFLN"
}
