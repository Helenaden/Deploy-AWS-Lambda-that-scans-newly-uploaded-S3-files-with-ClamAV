# Create a REST API.
resource "aws_api_gateway_rest_api" "presigner_api" {
  name        = "s3-presigner-api"
  description = "API for generating S3 pre-signed upload URLs"
}

# Create a resource (a URL path segment). This is the /upload resource.
resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.presigner_api.id
  parent_id   = aws_api_gateway_rest_api.presigner_api.root_resource_id
  path_part   = "upload"
}

# Create filename resource for path parameter
resource "aws_api_gateway_resource" "filename_resource" {
  rest_api_id = aws_api_gateway_rest_api.presigner_api.id
  parent_id   = aws_api_gateway_resource.upload_resource.id
  path_part   = "{fileName}"
}

# Update method to use filename resource
resource "aws_api_gateway_method" "get_presigned_url_method_with_filename" {
  rest_api_id   = aws_api_gateway_rest_api.presigner_api.id
  resource_id   = aws_api_gateway_resource.filename_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Method settings for caching
resource "aws_api_gateway_method_settings" "cache_settings" {
  rest_api_id = aws_api_gateway_rest_api.presigner_api.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  method_path = "*/*"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 300
  }
}

# Update integration to use filename resource
resource "aws_api_gateway_integration" "lambda_integration_with_filename" {
  rest_api_id = aws_api_gateway_rest_api.presigner_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.get_presigned_url_method_with_filename.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.s3_presigner_function.invoke_arn
}

# Add Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_presigner_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.presigner_api.execution_arn}/*/*"
}

# Create a deployment to make the API live.
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.presigner_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.presigner_api.body,
      aws_api_gateway_resource.upload_resource.id,
      aws_api_gateway_resource.filename_resource.id,
      aws_api_gateway_method.get_presigned_url_method_with_filename.id,
      aws_api_gateway_integration.lambda_integration_with_filename.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.presigner_api.id}/prod"
  retention_in_days = 7
}

# Create a separate stage resource that links to the deployment.
resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.presigner_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id

  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}



# Output the final URL. The path no longer includes a filename parameter.
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.prod_stage.invoke_url}/upload"
}

