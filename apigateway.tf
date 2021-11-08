
locals {
  bucket_uri = "https://${aws_s3_bucket.static_bucket.bucket_regional_domain_name}"
}

resource "aws_apigatewayv2_api" "api" {
  name          = var.name_base
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "static_file" {
  api_id = aws_apigatewayv2_api.api.id
  #   The route key for the route. 
  #   For HTTP APIs, the route key can be either $default, 
  #   or a combination of an HTTP method and resource path, for example, GET /pets.
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.static_file.id}"
}

resource "aws_apigatewayv2_route" "presign_lambda" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /api/presign"
  target    = "integrations/${aws_apigatewayv2_integration.presign_lambda.id}"
}

resource "aws_apigatewayv2_route" "credentials_lambda" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /api/credentials"
  target    = "integrations/${aws_apigatewayv2_integration.credentials_lambda.id}"
}

# Under the root resource, create a GET method
# Choose AWS Service as Integrations Type
# Region as the region in which the bucket is
# AWS Servie as S3
# HTTP method as GET
# Path Override as bucket-name/object-name
resource "aws_apigatewayv2_integration" "static_file" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = "${local.bucket_uri}/{proxy}"
}

resource "aws_apigatewayv2_integration" "presign_lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.presign_lambda.invoke_arn
}

resource "aws_apigatewayv2_integration" "credentials_lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.credentials_lambda.invoke_arn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/apigateway/${var.name_base}_access"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "api_stage_default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  #  Settings for logging access in this stage
  #   destination_arn - (Required) The ARN of the CloudWatch Logs log group to receive access logs
  #   format - (Required) A single line format of the access logs of data, as specified by selected $context variables.

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
    format = jsonencode(
      {
        status                    = "$context.status",
        httpMethod                = "$context.httpMethod",
        ip                        = "$context.identity.sourceIp",
        protocol                  = "$context.protocol",
        requestId                 = "$context.requestId",
        requestTime               = "$context.requestTime",
        responseLength            = "$context.responseLength",
        routeKey                  = "$context.routeKey",
        integration_error_status  = "$context.integrationStatus",
        integration_error_message = "$context.integrationErrorMessage",
        message                   = "$context.error.message",
        messageString             = "$context.error.messageString",
        context_path              = "$context.path"
    })
  }
}
