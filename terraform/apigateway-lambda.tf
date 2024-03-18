resource "aws_api_gateway_rest_api" "api" {
  provider = aws.app_local

  name = "mlapp-${terraform.workspace}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  disable_execute_api_endpoint = true
  tags = local.tags
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  provider = aws.app_local

  rest_api_id = aws_api_gateway_rest_api.api.id
  policy = templatefile("${path.module}/templates/api-gateway-policy.json", { })
}

resource "aws_api_gateway_resource" "resource" {
  provider = aws.app_local

  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  provider = aws.app_local

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"

  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  provider = aws.app_local

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_domain_name" "this" {
  provider = aws.app_local

  domain_name              = var.rest_api_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_base_path_mapping" "this" {
  provider = aws.app_local

  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.this.domain_name
  stage_name  = terraform.workspace
  base_path = ""
}

resource "aws_api_gateway_method_settings" "this" {
  provider = aws.app_local

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = terraform.workspace
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  provider = aws.app_local

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = terraform.workspace
  variables = {
    deployed_at = var.app_deployed_at
  }

  depends_on = [
    aws_api_gateway_integration.integration
  ]

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "stage" {
  provider = aws.app_local

  stage_name    = terraform.workspace
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

resource "aws_lambda_function" "lambda" {
  provider = aws.app_local

  s3_bucket     = var.backend_deploy_s3_bucket_name
  s3_key        = local.backend_deploy_artifact_s3_key
  function_name = "mlapp-${terraform.workspace}-api"
  handler       = "yes"
  role          = aws_iam_role.api_lambda_role.arn
  timeout       = 30
  memory_size   = 7168
  // The runtime of the lambda function
  runtime       = "provided.al2"

  environment {
    variables = {
      ENV = terraform.workspace
    }
  }
  depends_on = [
    aws_s3_object.app_archive_upload
  ]

  tags = local.tags
}
resource "aws_s3_object" "app_archive_upload" {
  provider = aws.app_local

  bucket = var.backend_deploy_s3_bucket_name
  key    = local.backend_deploy_artifact_s3_key

  source = "${path.module}/my_deployment_package.zip"

  tags = local.tags
  etag = filemd5("${path.module}/my_deployment_package.zip")
}
resource "aws_lambda_permission" "apigw_lambda" {
  provider = aws.app_local

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
