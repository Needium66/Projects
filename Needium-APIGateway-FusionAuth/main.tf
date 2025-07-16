##########################################################
#main.tf
########################################################
# main.tf

provider "aws" {
  region = var.aws_region
}

# --- IAM Roles for Lambda Functions ---

resource "aws_iam_role" "needium_lambda_exec_role" {
  name_prefix = "api-gateway-lambda-exec-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "needium_lambda_policy" {
  role       = aws_iam_role.needium_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Functions for Microservices ---

# Authentication Lambda (FusionAuth Custom Authorizer)
resource "aws_lambda_function" "needium_auth_lambda" {
  function_name = "fusionauth-custom-authorizer"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.needium_lambda_exec_role.arn
  filename      = data.archive_file.needium_auth_lambda_zip.output_path
  source_code_hash = data.archive_file.needium_auth_lambda_zip.output_base64sha256

  environment {
    variables = {
      FUSIONAUTH_DOMAIN = var.needium_fusionauth_domain
      FUSIONAUTH_API_KEY = var.needium_fusionauth_api_key # Consider Secrets Manager for production
    }
  }
}

data "archive_file" "needium_auth_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/needium_auth_lambda"
  output_path = "lambdas/needium_auth_lambda.zip"
}

# Payment Microservice Lambda
resource "aws_lambda_function" "needium_payment_lambda" {
  function_name = "needium-payment-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.needium_lambda_exec_role.arn
  filename      = data.archive_file.needium_payment_lambda_zip.output_path
  source_code_hash = data.archive_file.needium_payment_lambda_zip.output_base64sha256
}

data "archive_file" "needium_payment_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/needium_payment_lambda"
  output_path = "lambdas/needium_payment_lambda.zip"
}

# Telemedicine Microservice Lambda
resource "aws_lambda_function" "needium_telemedicine_lambda" {
  function_name = "needium-telemedicine-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.needium_lambda_exec_role.arn
  filename      = data.archive_file.needium_telemedicine_lambda_zip.output_path
  source_code_hash = data.archive_file.needium_telemedicine_lambda_zip.output_base64sha256
}

data "archive_file" "needium_telemedicine_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/needium_telemedicine_lambda"
  output_path = "lambdas/needium_telemedicine_lambda.zip"
}

# Pharmacy Microservice Lambda
resource "aws_lambda_function" "needium_pharmacy_lambda" {
  function_name = "needium-pharmacy-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.needium_lambda_exec_role.arn
  filename      = data.archive_file.needium_pharmacy_lambda_zip.output_path
  source_code_hash = data.archive_file.needium_pharmacy_lambda_zip.output_base64sha256
}

data "archive_file" "needium_pharmacy_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/needium_pharmacy_lambda"
  output_path = "lambdas/needium_pharmacy_lambda.zip"
}

# Personal Health Management Microservice Lambda
resource "aws_lambda_function" "needium_pfm_lambda" {
  function_name = "needium-personal-health-management-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.needium_lambda_exec_role.arn
  filename      = data.archive_file.needium_pfm_lambda_zip.output_path
  source_code_hash = data.archive_file.needium_pfm_lambda_zip.output_base64sha256
}

data "archive_file" "needium_pfm_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/needium_pfm_lambda"
  output_path = "lambdas/needium_pfm_lambda.zip"
}

# --- API Gateway REST API ---

resource "aws_api_gateway_rest_api" "needium_microservices_api" {
  name        = "MicroservicesAPI"
  description = "API Gateway for fan-out microservices"
}

# --- Custom Authorizer (FusionAuth Integration) ---

resource "aws_api_gateway_authorizer" "needium_fusionauth_authorizer" {
  name                   = "FusionAuthAuthorizer"
  type                   = "TOKEN" # For JWT validation
  rest_api_id            = aws_api_gateway_rest_api.needium_microservices_api.id
  authorizer_uri         = aws_lambda_function.needium_auth_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.needium_lambda_exec_role.arn # Role for API Gateway to invoke Lambda
  identity_source        = "method.request.header.Authorization" # Where to find the JWT
  identity_validation_expression = "^Bearer [a-zA-Z0-9\\-_\\.]+$" # Basic regex for Bearer token
  authorizer_result_ttl_in_seconds = 300 # Cache results for 5 minutes
}

# Grant API Gateway permission to invoke the authorizer Lambda
resource "aws_lambda_permission" "apigw_needium_auth_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuthLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.needium_auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_microservices_api.execution_arn}/*"
}

# --- API Gateway Resources (Paths) and Methods ---

# Root path for all microservices
resource "aws_api_gateway_resource" "needium_root_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_rest_api.needium_microservices_api.needium_root_resource_id
  path_part   = "{proxy+}" # Catch-all for sub-paths
}

# --- Payment Service ---
resource "aws_api_gateway_resource" "needium_payment_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_rest_api.neediu_microservices_api.needium_root_resource_id
  path_part   = "payments"
}

resource "aws_api_gateway_resource" "needium_payment_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_resource.needium_payment_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "needium_payment_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id   = aws_api_gateway_resource.needium_payment_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM" # Use custom authorizer
  authorizer_id = aws_api_gateway_authorizer.needium_fusionauth_authorizer.id
  api_key_required = true # Require API key for rate limiting
}

resource "aws_api_gateway_integration" "needium_payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id             = aws_api_gateway_resource.needium_payment_proxy_resource.id
  http_method             = aws_api_gateway_method.needium_payment_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # Lambda proxy integration typically uses POST
  uri                     = aws_lambda_function.needium_payment_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_needium_payment_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePaymentLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.needium_payment_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_microservices_api.execution_arn}/*/${aws_api_gateway_method.needium_payment_method_any.http_method}${aws_api_gateway_resource.needium_payment_resource.path_part}/*"
}

# --- Telemedicine Service ---
resource "aws_api_gateway_resource" "needium_telemedicine_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_rest_api.needium_microservices_api.needium_root_resource_id
  path_part   = "telemedicine"
}

resource "aws_api_gateway_resource" "needium_telemedicine_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_resource.needium_telemedicine_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "needium_telemedicine_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id   = aws_api_gateway_resource.needium_telemedicine_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.needium_fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "needium_telemedicine_integration" {
  rest_api_id             = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id             = aws_api_gateway_resource.needium_telemedicine_proxy_resource.id
  http_method             = aws_api_gateway_method.needium_telemedicine_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.needium_telemedicine_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_needium_telemedicine_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeTelemedicineLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.needium_telemedicine_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_microservices_api.execution_arn}/*/${aws_api_gateway_method.needium_telemedicine_method_any.http_method}${aws_api_gateway_resource.needium_telemedicine_resource.path_part}/*"
}

# --- Pharmacy Service ---
resource "aws_api_gateway_resource" "needium_pharmacy_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_rest_api.needium_microservices_api.needium_root_resource_id
  path_part   = "pharmacy"
}

resource "aws_api_gateway_resource" "needium_pharmacy_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_resource.needium_pharmacy_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "needium_pharmacy_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id   = aws_api_gateway_resource.needium_pharmacy_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.needium_fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "needium_pharmacy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id             = aws_api_gateway_resource.needium_pharmacy_proxy_resource.id
  http_method             = aws_api_gateway_method.needium_pharmacy_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.needium_pharmacy_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_needium_pharmacy_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePharmacyLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.needium_pharmacy_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_microservices_api.execution_arn}/*/${aws_api_gateway_method.needium_pharmacy_method_any.http_method}${aws_api_gateway_resource.needium_pharmacy_resource.path_part}/*"
}

# --- Personal Health Management Service ---
resource "aws_api_gateway_resource" "needium_pfm_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_rest_api.needium_microservices_api.needium_root_resource_id
  path_part   = "personal-health-management"
}

resource "aws_api_gateway_resource" "needium_pfm_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  parent_id   = aws_api_gateway_resource.needium_pfm_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "needium_pfm_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id   = aws_api_gateway_resource.needium_pfm_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.needium_fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "needium_pfm_integration" {
  rest_api_id             = aws_api_gateway_rest_api.needium_microservices_api.id
  resource_id             = aws_api_gateway_resource.needium_pfm_proxy_resource.id
  http_method             = aws_api_gateway_method.needium_pfm_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.needium_pfm_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_needium_pfm_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePFMLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.needium_pfm_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_microservices_api.execution_arn}/*/${aws_api_gateway_method.needium_pfm_method_any.http_method}${aws_api_gateway_resource.needium_pfm_resource.path_part}/*"
}

# --- API Gateway Deployment and Stage ---

resource "aws_api_gateway_deployment" "needium_microservices_deployment" {
  rest_api_id = aws_api_gateway_rest_api.needium_microservices_api.id
  # Note: The `triggers` block forces a new deployment on API changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.needium_root_resource.id,
      aws_api_gateway_method.needium_payment_method_any.id,
      aws_api_gateway_integration.needium_payment_integration.id,
      aws_api_gateway_method.needium_telemedicine_method_any.id,
      aws_api_gateway_integration.needium_telemedicine_integration.id,
      aws_api_gateway_method.needium_pharmacy_method_any.id,
      aws_api_gateway_integration.needium_pharmacy_integration.id,
      aws_api_gateway_method.needium_pfm_method_any.id,
      aws_api_gateway_integration.needium_pfm_integration.id,
      aws_api_gateway_authorizer.needium_fusionauth_authorizer.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "needium_prod" {
  deployment_id = aws_api_gateway_deployment.needium_microservices_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  stage_name    = "needium_prod"
  description   = "Production stage"

  # Enable CloudWatch logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      "requestId" : "$context.requestId",
      "ip" : "$context.identity.sourceIp",
      "caller" : "$context.identity.caller",
      "user" : "$context.identity.user",
      "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength"
    })
  }

  # Method settings for all methods in this stage (can be overridden per method)
  # This is where we apply rate limiting settings globally for the stage
  xray_tracing_enabled = true # Enable X-Ray tracing for better observability
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/microservices-api"
  retention_in_days = 7
}

# --- API Key and Usage Plan for Rate Limiting ---

resource "aws_api_gateway_api_key" "main_api_key" {
  name        = "MicroservicesAPIKey"
  description = "API Key for accessing Microservices API"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "high_throughput_plan" {
  name        = "HighThroughputPlan"
  description = "Usage plan for high throughput users"

  api_stages {
    api_id = aws_api_gateway_rest_api.needium_microservices_api.id
    stage  = aws_api_gateway_stage.needium_prod.stage_name
    throttle {
      path        = "ANY /payments/{proxy+}" # Example throttling for payment service
      rate_limit  = 100                    # Requests per second
      burst_limit = 200                    # Maximum concurrent requests
    }
    throttle {
      path        = "ANY /telemedicine/{proxy+}"
      rate_limit  = 50
      burst_limit = 100
    }
    throttle {
      path        = "ANY /pharmacy/{proxy+}"
      rate_limit  = 50
      burst_limit = 100
    }
    throttle {
      path        = "ANY /personal-health-management/{proxy+}"
      rate_limit  = 20
      burst_limit = 40
    }
  }

  # Overall quota settings for the usage plan
  quota_settings {
    limit  = 100000 # Total requests per period
    period = "MONTH"
  }
}

resource "aws_api_gateway_usage_plan_key" "main_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.main_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.high_throughput_plan.id
}

# --- Response Processing (Example for 4xx/5xx errors) ---

resource "aws_api_gateway_gateway_response" "unauthorized_response" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  response_type = "UNAUTHORIZED"
  status_code   = "401"
  response_templates = {
    "application/json" = jsonencode({
      "message" : "$context.error.messageString",
      "code" : "UNAUTHORIZED"
    })
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }
}

resource "aws_api_gateway_gateway_response" "bad_request_response" {
  rest_api_id   = aws_api_gateway_rest_api.needium_microservices_api.id
  response_type = "BAD_REQUEST_BODY"
  status_code   = "400"
  response_templates = {
    "application/json" = jsonencode({
      "message" : "Invalid request body.",
      "details" : "$context.error.validationErrorString"
    })
  }
}

# You can add more gateway responses for other error types (e.g., ACCESS_DENIED, DEFAULT_5XX)
# For specific Lambda response processing, it's typically handled within the Lambda function itself
# using its return structure for proxy integration.