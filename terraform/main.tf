locals {
  tags = {
    "env" = terraform.workspace
    "project" = "sekkeicm-rd-verification"
  }
  backend_deploy_artifact_s3_key = "lambda/backend-restapi-${var.app_deployed_at}.zip"
}
