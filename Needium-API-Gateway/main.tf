####################################################################################
#Main: The main file
####################################################################################
# main.tf

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# 1. AWS API Gateway Setup
# -----------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "needium_api" {
  name        = var.api_gateway_name
  description = "API Gateway for Healthcare Microservices"

  tags = {
    Project = var.project_name
  }
}

# -----------------------------------------------------------------------------
# 2. User Management (Login, Session, Prompt) with AWS Cognito
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool" "main_user_pool" {
  name = var.cognito_user_pool_name

  auto_verified_attributes = ["email"]

  schema {
    name     = "email"
    attribute_data_type = "String"
    mutable  = true
    required = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
    require_symbols   = true
  }

  # Add tags for better resource management
  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "main_user_pool_client" {
  name         = "${var.project_name}-AppClient"
  user_pool_id = aws_cognito_user_pool.main_user_pool.id

  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_SRP_AUTH", "CUSTOM_AUTH_FLOW_ONLY"]
  # Allow unauthenticated access for login/signup flows if needed, or secure via API Gateway
  # For this example, we'll assume the client handles authentication and sends JWTs.
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = ["http://localhost:3000/callback", "https://your-frontend-domain.com/callback"] # Replace with your actual frontend URLs
  logout_urls                          = ["http://localhost:3000/logout", "https://your-frontend-domain.com/logout"]   # Replace with your actual frontend URLs
  supported_identity_providers         = ["COGNITO"]

  # Add tags
  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_domain" "main_user_pool_domain" {
  domain       = "${lower(var.project_name)}-api-gateway-auth" # Unique domain name
  user_pool_id = aws_cognito_user_pool.main_user_pool.id

  # Add tags
  tags = {
    Project = var.project_name
  }
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "${var.project_name}-CognitoAuthorizer"
  type                   = "COGNITO_USER_POOLS"
  rest_api_id            = aws_api_gateway_rest_api.needium_api.id
  provider_arns          = [aws_cognito_user_pool.main_user_pool.arn]
  identity_source        = "method.request.header.Authorization" # Expects JWT in Authorization header
  authorizer_result_ttl_in_seconds = 300 # Cache authorization results for 5 minutes
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec_role.name
}

data "aws_partition" "current" {} # Used to get the partition for ARN construction

# -----------------------------------------------------------------------------
# Lambda Functions (Microservices - HealthAPIGateway)
# -----------------------------------------------------------------------------

# Payment Service Lambda
resource "aws_lambda_function" "payment_service_lambda" {
  function_name = "${var.project_name}-PaymentService"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.payment_service_zip.output_path
  source_code_hash = data.archive_file.payment_service_zip.output_base64sha256

  tags = {
    Service = "Payment"
    Project = var.project_name
  }
}

data "archive_file" "payment_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/payment_service"
  output_path = "${path.module}/lambda/payment_service.zip"
}

# Telemedicine Service Lambda
resource "aws_lambda_function" "telemedicine_service_lambda" {
  function_name = "${var.project_name}-TelemedicineService"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.telemedicine_service_zip.output_path
  source_code_hash = data.archive_file.telemedicine_service_zip.output_base64sha256

  tags = {
    Service = "Telemedicine"
    Project = var.project_name
  }
}

data "archive_file" "telemedicine_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/telemedicine_service"
  output_path = "${path.module}/lambda/telemedicine_service.zip"
}

# Pharmacy Service Lambda
resource "aws_lambda_function" "pharmacy_service_lambda" {
  function_name = "${var.project_name}-PharmacyService"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.pharmacy_service_zip.output_path
  source_code_hash = data.archive_file.pharmacy_service_zip.output_base64sha256

  tags = {
    Service = "Pharmacy"
    Project = var.project_name
  }
}

data "archive_file" "pharmacy_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/pharmacy_service"
  output_path = "${path.module}/lambda/pharmacy_service.zip"
}

# Personal Health Management Service Lambda
resource "aws_lambda_function" "personal_health_service_lambda" {
  function_name = "${var.project_name}-PersonalHealthService"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.personal_health_service_zip.output_path
  source_code_hash = data.archive_file.personal_health_service_zip.output_base64sha256

  tags = {
    Service = "PersonalHealth"
    Project = var.project_name
  }
}

data "archive_file" "personal_health_service_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/personal_health_service"
  output_path = "${path.module}/lambda/personal_health_service.zip"
}

# User Management Lambda (for prompt/session logic, beyond Cognito login)
resource "aws_lambda_function" "user_management_lambda" {
  function_name = "${var.project_name}-UserManagementService"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.user_management_zip.output_path
  source_code_hash = data.archive_file.user_management_zip.output_base64sha256

  tags = {
    Service = "UserManagement"
    Project = var.project_name
  }
}

data "archive_file" "user_management_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/user_management"
  output_path = "${path.module}/lambda/user_management.zip"
}


# -----------------------------------------------------------------------------
# API Gateway Resources and Methods
# -----------------------------------------------------------------------------

# Root resource (/)
resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.needium_api.id
  parent_id   = aws_api_gateway_rest_api.needium_api.root_resource_id
  path_part   = "{proxy+}" # Catch-all for unhandled paths, or could be a welcome message
}

resource "aws_api_gateway_method" "root_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.needium_api.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "GET"
  authorization = "NONE" # Public welcome message
}

resource "aws_api_gateway_integration" "root_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.needium_api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.root_get_method.http_method
  type        = "MOCK" # Simple mock response for root
  request_templates = {
    "application/json" = "{}"
  }
}

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.needium_api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.root_get_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty" # Define a model if needed
  }
}

resource "aws_api_gateway_integration_response" "root_get_integration_200" {
  rest_api_id = aws_api_gateway_rest_api.needium_api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.root_get_method.http_method
  status_code = aws_api_gateway_method_response.root_get_200.status_code
  selection_pattern = "" # Match any successful response
  response_templates = {
    "application/json" = jsonencode({ message = "Welcome to the Healthcare Microservices API! Please refer to the documentation for available endpoints." })
  }
}


# Helper for API Gateway Lambda integration
resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  for_each = {
    payment_service          = aws_lambda_function.payment_service_lambda.arn
    telemedicine_service     = aws_lambda_function.telemedicine_service_lambda.arn
    pharmacy_service         = aws_lambda_function.pharmacy_service_lambda.arn
    personal_health_service  = aws_lambda_function.personal_health_service_lambda.arn
    user_management          = aws_lambda_function.user_management_lambda.arn
  }

  statement_id  = "AllowAPIGatewayInvokeLambda${replace(each.key, "_", "")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.needium_api.execution_arn}/*/*"
}

# Function to create API Gateway resources, methods, and integrations for microservices
module "api_microservice" {
  source = "./modules/api_microservice" # Using a local module for repetition

  for_each = {
    payments          = aws_lambda_function.payment_service_lambda.arn
    telemedicine      = aws_lambda_function.telemedicine_service_lambda.arn
    pharmacy          = aws_lambda_function.pharmacy_service_lambda.arn
    health            = aws_lambda_function.personal_health_service_lambda.arn
    users             = aws_lambda_function.user_management_lambda.arn
  }

  rest_api_id       = aws_api_gateway_rest_api.needium_api.id
  parent_resource_id = aws_api_gateway_rest_api.needium_api.root_resource_id
  path_part         = each.key
  lambda_arn        = each.value
  authorizer_id     = aws_api_gateway_authorizer.cognito_authorizer.id
  project_name      = var.project_name
}


# -----------------------------------------------------------------------------
# API Gateway Deployment and Stage
# -----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "main_deployment" {
  rest_api_id = aws_api_gateway_rest_api.needium_api.id

  # This 'triggers' block ensures a new deployment happens when any of the
  # API Gateway methods or integrations change.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root_resource.id,
      aws_api_gateway_method.root_get_method.id,
      aws_api_gateway_integration.root_get_integration.id,
      for key, module in module.api_microservice : module.resource_id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.root_get_method,
    aws_api_gateway_integration.root_get_integration,
    aws_api_gateway_method_response.root_get_200,
    aws_api_gateway_integration_response.root_get_integration_200,
    module.api_microservice
  ]
}

resource "aws_api_gateway_stage" "main_stage" {
  deployment_id = aws_api_gateway_deployment.main_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.needium_api.id
  stage_name    = var.api_gateway_stage_name

  # Enable logging (CloudWatch Logs)
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId               = "$context.requestId",
      ip                      = "$context.identity.sourceIp",
      caller                  = "$context.identity.caller",
      user                    = "$context.identity.user",
      requestTime             = "$context.requestTime",
      httpMethod              = "$context.httpMethod",
      resourcePath            = "$context.resourcePath",
      status                  = "$context.status",
      protocol                = "$context.protocol",
      responseLength          = "$context.responseLength",
      cognitoAuthenticationStatus = "$context.authorizer.claims.cognito:username" # Example for Cognito
    })
  }

  # Enable caching (optional, but good for performance)
  # cache_cluster_enabled = true
  # cache_cluster_size    = "0.5" # 0.5 GB

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${var.api_gateway_name}-${var.api_gateway_stage_name}"
  retention_in_days = 7 # Adjust retention as needed

  tags = {
    Project = var.project_name
  }
}

# -----------------------------------------------------------------------------
# 3. Rate Limiting
# -----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan" "default_usage_plan" {
  name        = "${var.project_name}-DefaultUsagePlan"
  description = "Default usage plan with rate limiting."

  api_stages {
    api_id = aws_api_gateway_rest_api.needium_api.id
    stage  = aws_api_gateway_stage.main_stage.stage_name
  }

  throttle_settings {
    burst_limit = var.default_rate_limit_burst
    rate_limit  = var.default_rate_limit_rate
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_api_gateway_api_key" "default_api_key" {
  name        = "${var.project_name}-DefaultApiKey"
  description = "API Key for default usage plan."
  enabled     = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_api_gateway_usage_plan_key" "default_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.default_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.default_usage_plan.id
}

# -----------------------------------------------------------------------------
# Local Module for Microservice API Gateway setup (to reduce repetition)
# Create a folder named 'modules/api_microservice' and put 'main.tf' inside it.
# -----------------------------------------------------------------------------