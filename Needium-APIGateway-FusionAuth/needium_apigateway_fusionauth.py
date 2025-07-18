##################################################################################################
#This project deploys an API Gateway managed Microservices with Fusion Auth as User Authenticator
#It also deploys independent of modules; different from earlier deployment
#It is also powered by Lambda, similar to initial API Gateway deployment
##################################################################################################
#Core Concepts:
#####################

# AWS API Gateway (REST API): Using a REST API to define endpoints and integrate with backend services.

# Path-based Routing: Each microservice will have a distinct base path (e.g., /payments, /telemedicine etc).

# AWS Lambda: Using Lambda functions as the backend for our microservices, invoked by API Gateway.
# Note: The actual Lambda code for each microservice is beyond the scope of this Terraform example, but function resources will be defined.

# FusionAuth: Integration with FusionAuth for authentication will involve a Custom Authorizer Lambda Function that validates JWTs issued by FusionAuth.

# Response Processing: Basic response mapping will be demonstrated.

# Rate Limiting: Implemented using API Gateway usage plans and throttling.

# Scalability: AWS API Gateway is inherently scalable. Configurations will leverage this by defining appropriate settings.
########################################################################################################################################
#Directory Structure:
######################################
# .
# ├── main.tf
# ├── variables.tf
# ├── outputs.tf
# ├── lambdas/
# │   ├── auth_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── payment_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── telemedicine_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── pharmacy_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   └── pfm_lambda/
# │       ├── main.py
# │       └── requirements.txt
# └── scripts/
#     └── package_lambdas.sh
################################################################################################
#main.tf:
#It is the Main Terraform Configuration.
#It Defines the AWS API Gateway, Lambda Functions, IAM Roles and their integrations
###############################################################################################
#variables.tf:
#It is the input variables file. It defines the variables for the terraform configuration
###############################################################################################
#outputs.tf:
#It is the outputs file. It enables some resources to be externally provided and reused
###############################################################################################
#Lambda Function Code:
########################################
#Fusion Auth Custom Authorizer: To validate JSON Web Tokens(JWTs) issued by FusionAuth
##############################################################################################
#Lambda Payment Function Code: The Bare Minimum Code for Payment Microservice
##############################################################################################
#Lambda TeleMedicine Function Code: The Bare Minimum Code for Telemedicine Microservice
##############################################################################################
#Lambda Pharmacy Function Code: The Bare Minimum Code for Pharmacy Microservice
################################################################################################
#Lambda Personal Health Management Function Code: The Bare Minimum Code for Payment Microservice
##############################################################################################################################
#Helper Scripts for Lambda Zips: To make templates more efficient by creating zip files for lambda functions with dependencies
#Small, reusable piece of code, to automate tasks within the deployment; to perform repetive actions
##############################################################################################################################
#Implementation Steps:
# Implementation Steps:

# Install Terraform: If you haven't already, install Terraform: https://developer.hashicorp.com/terraform/downloads

# Set up AWS CLI: Configure your AWS CLI with appropriate credentials and default region. Terraform will use these.

# Set up FusionAuth:

# - Deploy a FusionAuth instance (e.g., using Docker, a cloud provider, or their hosted solution).

# - Create an application within FusionAuth.

# - Generate an API Key with permissions to POST /api/jwt/validate. For simplicity, you can create a superuser key initially,
# but narrow down permissions for production.

# - Note your FusionAuth domain (e.g., https://your-fusionauth.com) and the API Key.

# Prepare Lambda Code:

# - Create the lambdas/ directory and its subdirectories as shown in the structure.

# - Place the Python code and requirements.txt files into their respective directories.

# - Run scripts/package_lambdas.sh to create the .zip files for your Lambda functions. You'll need pip installed.
###############################################################################################################################
#Intialize Terraform: 
#terraform init
#########################################
#Plan the Deployment:
#terraform plan -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
#NOTE: Replace YOUR_FUSIONAUTH_DOMAIN and YOUR_FUSIONAUTH_API_KEY with your actual FusionAuth details. It's best practice 
#to use a .tfvars file or environment variables for sensitive data rather than passing them directly on the command line for production
########################################################################################################################################
#Apply the Configuration:
#terraform apply -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
######################################################################################################################
#Test the API:
##########################################################
# After terraform apply completes, you will get an api_gateway_base_url output.

# You will also get an api_key_value.

# To test, you'll need a JWT from FusionAuth. You can obtain one by logging in a user to your FusionAuth application and 
# inspecting network requests, or by using their /oauth2/token endpoint.
#########################################################################################################################
#Curl Commands Examples:
##############################################
# Login/Session Management (via FusionAuth directly):
# This part is handled directly by FusionAuth's OAuth endpoints. Your client application (e.g., web app, mobile app) 
# would interact with FusionAuth for login and session management, receiving a JWT.

# Prompt Management:
# Prompt management (e.g., password resets, MFA prompts) are also features handled directly by FusionAuth's hosted login pages 
# or APIs that your client application integrates with.
###############################################################################################################################
# Get the base URL from Terraform output
# API_URL=$(terraform output -raw api_gateway_base_url)
# API_KEY=$(terraform output -raw api_key_value) # Use this in X-Api-Key header

# # Assume you have a JWT_TOKEN obtained from FusionAuth
# JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Replace with your actual JWT

# # Test Payment Service
# curl -v -X POST \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"amount": 100, "currency": "USD"}' \
#   "${API_URL}/prod/payments/charge"

# # Test Telemedicine Service
# curl -v -X GET \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   "${API_URL}/prod/telemedicine/appointments"

# # Test Pharmacy Service
# curl -v -X POST \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"prescription_id": "XYZ123"}' \
#   "${API_URL}/prod/pharmacy/order"

# # Test Personal Health Management Service
# curl -v -X PUT \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"weight": 180, "date": "2025-07-16"}' \
#   "${API_URL}/prod/personal-health-management/metrics/weight"

# Test Unauthorized Access (without token)
# curl -v -X GET "${API_URL}/prod/payments/charge"

# Test Rate Limiting (send many requests quickly with the API_KEY)
# You'll start seeing 429 Too Many Requests errors if you exceed the throttle limits
###########################################################################################################################
As a professional developer, let's build out an AWS API Gateway leveraging Terraform for your microservices architecture, fanning out to payment, telemedicine, pharmacy, and personal health management services. We'll ensure routing via path, incorporate FusionAuth for user management, handle response processing, implement rate limiting, and design for scalability.

This solution will not use Terraform modules for the API Gateway configuration to strictly adhere to your request. However, in a larger production environment, creating reusable modules for common patterns (like Lambda integrations or API Gateway methods) is highly recommended for maintainability and consistency.

Core Concepts:

AWS API Gateway (REST API): We'll use a REST API to define our endpoints and integrate with backend services.

Path-based Routing: Each microservice will have a distinct base path (e.g., /payments, /telemedicine).

AWS Lambda: We'll use Lambda functions as the backend for our microservices, invoked by API Gateway. (Note: The actual Lambda code for each microservice is beyond the scope of this Terraform example, but we'll define the function resources).

FusionAuth: Integration with FusionAuth for authentication will involve a custom authorizer Lambda function that validates JWTs issued by FusionAuth.

Response Processing: We'll demonstrate basic response mapping.

Rate Limiting: Implemented using API Gateway usage plans and throttling.

Scalability: AWS API Gateway is inherently scalable. We'll ensure our configuration leverages this by defining appropriate settings.

Directory Structure:

.
├── main.tf
├── variables.tf
├── outputs.tf
├── lambdas/
│   ├── auth_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── payment_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── telemedicine_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── pharmacy_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   └── pfm_lambda/
│       ├── main.py
│       └── requirements.txt
└── scripts/
    └── package_lambdas.sh
1. main.tf - Main Terraform Configuration

This file will define the AWS API Gateway, Lambda functions, IAM roles, and their integrations.

Terraform

# main.tf

provider "aws" {
  region = var.aws_region
}

# --- IAM Roles for Lambda Functions ---

resource "aws_iam_role" "lambda_exec_role" {
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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Functions for Microservices ---

# Authentication Lambda (FusionAuth Custom Authorizer)
resource "aws_lambda_function" "auth_lambda" {
  function_name = "fusionauth-custom-authorizer"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.auth_lambda_zip.output_path
  source_code_hash = data.archive_file.auth_lambda_zip.output_base64sha256

  environment {
    variables = {
      FUSIONAUTH_DOMAIN = var.fusionauth_domain
      FUSIONAUTH_API_KEY = var.fusionauth_api_key # Consider Secrets Manager for production
    }
  }
}

data "archive_file" "auth_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/auth_lambda"
  output_path = "lambdas/auth_lambda.zip"
}

# Payment Microservice Lambda
resource "aws_lambda_function" "payment_lambda" {
  function_name = "payment-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.payment_lambda_zip.output_path
  source_code_hash = data.archive_file.payment_lambda_zip.output_base64sha256
}

data "archive_file" "payment_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/payment_lambda"
  output_path = "lambdas/payment_lambda.zip"
}

# Telemedicine Microservice Lambda
resource "aws_lambda_function" "telemedicine_lambda" {
  function_name = "telemedicine-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.telemedicine_lambda_zip.output_path
  source_code_hash = data.archive_file.telemedicine_lambda_zip.output_base64sha256
}

data "archive_file" "telemedicine_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/telemedicine_lambda"
  output_path = "lambdas/telemedicine_lambda.zip"
}

# Pharmacy Microservice Lambda
resource "aws_lambda_function" "pharmacy_lambda" {
  function_name = "pharmacy-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.pharmacy_lambda_zip.output_path
  source_code_hash = data.archive_file.pharmacy_lambda_zip.output_base64sha256
}

data "archive_file" "pharmacy_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/pharmacy_lambda"
  output_path = "lambdas/pharmacy_lambda.zip"
}

# Personal Health Management Microservice Lambda
resource "aws_lambda_function" "pfm_lambda" {
  function_name = "personal-health-management-microservice"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.pfm_lambda_zip.output_path
  source_code_hash = data.archive_file.pfm_lambda_zip.output_base64sha256
}

data "archive_file" "pfm_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/pfm_lambda"
  output_path = "lambdas/pfm_lambda.zip"
}

# --- API Gateway REST API ---

resource "aws_api_gateway_rest_api" "microservices_api" {
  name        = "MicroservicesAPI"
  description = "API Gateway for fan-out microservices"
}

# --- Custom Authorizer (FusionAuth Integration) ---

resource "aws_api_gateway_authorizer" "fusionauth_authorizer" {
  name                   = "FusionAuthAuthorizer"
  type                   = "TOKEN" # For JWT validation
  rest_api_id            = aws_api_gateway_rest_api.microservices_api.id
  authorizer_uri         = aws_lambda_function.auth_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.lambda_exec_role.arn # Role for API Gateway to invoke Lambda
  identity_source        = "method.request.header.Authorization" # Where to find the JWT
  identity_validation_expression = "^Bearer [a-zA-Z0-9\\-_\\.]+$" # Basic regex for Bearer token
  authorizer_result_ttl_in_seconds = 300 # Cache results for 5 minutes
}

# Grant API Gateway permission to invoke the authorizer Lambda
resource "aws_lambda_permission" "apigw_auth_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuthLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*"
}

# --- API Gateway Resources (Paths) and Methods ---

# Root path for all microservices
resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "{proxy+}" # Catch-all for sub-paths
}

# --- Payment Service ---
resource "aws_api_gateway_resource" "payment_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "payments"
}

resource "aws_api_gateway_resource" "payment_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.payment_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "payment_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.payment_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM" # Use custom authorizer
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true # Require API key for rate limiting
}

resource "aws_api_gateway_integration" "payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.payment_proxy_resource.id
  http_method             = aws_api_gateway_method.payment_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # Lambda proxy integration typically uses POST
  uri                     = aws_lambda_function.payment_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_payment_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePaymentLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*/${aws_api_gateway_method.payment_method_any.http_method}${aws_api_gateway_resource.payment_resource.path_part}/*"
}

# --- Telemedicine Service ---
resource "aws_api_gateway_resource" "telemedicine_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "telemedicine"
}

resource "aws_api_gateway_resource" "telemedicine_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.telemedicine_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "telemedicine_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.telemedicine_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "telemedicine_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.telemedicine_proxy_resource.id
  http_method             = aws_api_gateway_method.telemedicine_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.telemedicine_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_telemedicine_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeTelemedicineLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telemedicine_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*/${aws_api_gateway_method.telemedicine_method_any.http_method}${aws_api_gateway_resource.telemedicine_resource.path_part}/*"
}

# --- Pharmacy Service ---
resource "aws_api_gateway_resource" "pharmacy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "pharmacy"
}

resource "aws_api_gateway_resource" "pharmacy_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.pharmacy_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "pharmacy_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.pharmacy_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "pharmacy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.pharmacy_proxy_resource.id
  http_method             = aws_api_gateway_method.pharmacy_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.pharmacy_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_pharmacy_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePharmacyLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pharmacy_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*/${aws_api_gateway_method.pharmacy_method_any.http_method}${aws_api_gateway_resource.pharmacy_resource.path_part}/*"
}

# --- Personal Health Management Service ---
resource "aws_api_gateway_resource" "pfm_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "personal-health-management"
}

resource "aws_api_gateway_resource" "pfm_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.pfm_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "pfm_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.pfm_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "pfm_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.pfm_proxy_resource.id
  http_method             = aws_api_gateway_method.pfm_method_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.pfm_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_pfm_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokePFMLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pfm_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*/${aws_api_gateway_method.pfm_method_any.http_method}${aws_api_gateway_resource.pfm_resource.path_part}/*"
}

# --- API Gateway Deployment and Stage ---

resource "aws_api_gateway_deployment" "microservices_deployment" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  # Note: The `triggers` block forces a new deployment on API changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root_resource.id,
      aws_api_gateway_method.payment_method_any.id,
      aws_api_gateway_integration.payment_integration.id,
      aws_api_gateway_method.telemedicine_method_any.id,
      aws_api_gateway_integration.telemedicine_integration.id,
      aws_api_gateway_method.pharmacy_method_any.id,
      aws_api_gateway_integration.pharmacy_integration.id,
      aws_api_gateway_method.pfm_method_any.id,
      aws_api_gateway_integration.pfm_integration.id,
      aws_api_gateway_authorizer.fusionauth_authorizer.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.microservices_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  stage_name    = "prod"
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
    api_id = aws_api_gateway_rest_api.microservices_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
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
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
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
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
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
2. variables.tf - Input Variables

Terraform

# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "fusionauth_domain" {
  description = "The domain name of your FusionAuth instance (e.g., https://your-fusionauth-instance.com)"
  type        = string
  sensitive   = true
}

variable "fusionauth_api_key" {
  description = "The API Key for your FusionAuth instance. Used by the custom authorizer to validate tokens."
  type        = string
  sensitive   = true
}
3. outputs.tf - Output Variables

Terraform

# outputs.tf

output "api_gateway_base_url" {
  description = "The base URL of the deployed API Gateway"
  value       = aws_api_gateway_deployment.microservices_deployment.invoke_url
}

output "api_key_value" {
  description = "The value of the generated API Key for the Microservices API"
  value       = aws_api_gateway_api_key.main_api_key.value
  sensitive   = true
}
4. Lambda Function Code (Place these in the lambdas/ directory)

lambdas/auth_lambda/main.py (FusionAuth Custom Authorizer)

Python

# lambdas/auth_lambda/main.py
import json
import os
import requests

FUSIONAUTH_DOMAIN = os.environ.get("FUSIONAUTH_DOMAIN")
FUSIONAUTH_API_KEY = os.environ.get("FUSIONAUTH_API_KEY")

def generate_policy(principal_id, effect, resource):
    auth_response = {}
    auth_response['principalId'] = principal_id

    if effect and resource:
        policy_document = {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
        auth_response['policyDocument'] = policy_document
    return auth_response

def handler(event, context):
    try:
        token = event['authorizationToken']
        if not token or not token.startswith("Bearer "):
            print("Invalid or missing Bearer token")
            raise Exception("Unauthorized")

        jwt = token.split(" ")[1]

        # Call FusionAuth to validate the JWT
        headers = {
            "Authorization": FUSIONAUTH_API_KEY,
            "Content-Type": "application/json"
        }
        validate_url = f"{FUSIONAUTH_DOMAIN}/api/jwt/validate"
        body = json.dumps({"jwt": jwt})

        response = requests.post(validate_url, headers=headers, data=body)
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)

        validation_result = response.json()

        if validation_result.get('isValid'):
            # Assuming the JWT payload contains user information in 'jwt.sub' (subject)
            # You might want to extract more user info from the decoded JWT payload
            # for context in your backend services.
            # FusionAuth often puts user ID in 'sub' and roles/permissions in custom claims.
            principal_id = validation_result.get('jwt', {}).get('sub', 'unknown')
            print(f"Token is valid for principal: {principal_id}")
            return generate_policy(principal_id, 'Allow', event['methodArn'])
        else:
            print(f"Token validation failed: {validation_result.get('error')}")
            raise Exception("Unauthorized")

    except requests.exceptions.RequestException as e:
        print(f"Error calling FusionAuth: {e}")
        raise Exception("Unauthorized")
    except Exception as e:
        print(f"Authentication error: {e}")
        raise Exception("Unauthorized")

lambdas/auth_lambda/requirements.txt

requests
lambdas/payment_lambda/main.py (Example Microservice Lambda)

Python

# lambdas/payment_lambda/main.py
import json

def handler(event, context):
    print(f"Payment Microservice received event: {json.dumps(event)}")
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    body = event.get('body', '{}')

    response_body = {
        "message": f"Hello from Payment Service!",
        "received_path": path,
        "http_method": method,
        "body_received": json.loads(body) if body else {},
        "action": "Payment processed successfully (mock response)."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
lambdas/payment_lambda/requirements.txt
(Empty, as this example doesn't have external dependencies, but you'd list them here)

lambdas/telemedicine_lambda/main.py

Python

# lambdas/telemedicine_lambda/main.py
import json

def handler(event, context):
    print(f"Telemedicine Microservice received event: {json.dumps(event)}")
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    body = event.get('body', '{}')

    response_body = {
        "message": f"Hello from Telemedicine Service!",
        "received_path": path,
        "http_method": method,
        "body_received": json.loads(body) if body else {},
        "action": "Telemedicine consultation scheduled (mock response)."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
lambdas/telemedicine_lambda/requirements.txt
(Empty)

lambdas/pharmacy_lambda/main.py

Python

# lambdas/pharmacy_lambda/main.py
import json

def handler(event, context):
    print(f"Pharmacy Microservice received event: {json.dumps(event)}")
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    body = event.get('body', '{}')

    response_body = {
        "message": f"Hello from Pharmacy Service!",
        "received_path": path,
        "http_method": method,
        "body_received": json.loads(body) if body else {},
        "action": "Prescription filled (mock response)."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
lambdas/pharmacy_lambda/requirements.txt
(Empty)

lambdas/pfm_lambda/main.py

Python

# lambdas/pfm_lambda/main.py
import json

def handler(event, context):
    print(f"Personal Health Management Microservice received event: {json.dumps(event)}")
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    body = event.get('body', '{}')

    response_body = {
        "message": f"Hello from Personal Health Management Service!",
        "received_path": path,
        "http_method": method,
        "body_received": json.loads(body) if body else {},
        "action": "Health data updated (mock response)."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
lambdas/pfm_lambda/requirements.txt
(Empty)

5. scripts/package_lambdas.sh (Helper Script for Lambda Zips)

Bash

#!/bin/bash
set -e

# This script creates zip files for Lambda functions with their dependencies.
# In a real CI/CD pipeline, this would be automated more robustly.

# Auth Lambda
echo "Packaging auth_lambda..."
cd lambdas/auth_lambda
pip install -r requirements.txt -t .
zip -r ../auth_lambda.zip .
rm -rf lib python *.dist-info # Clean up downloaded packages
cd ../..

# Payment Lambda
echo "Packaging payment_lambda..."
cd lambdas/payment_lambda
# No requirements.txt for this example, but if there were:
# pip install -r requirements.txt -t .
zip -r ../payment_lambda.zip .
cd ../..

# Telemedicine Lambda
echo "Packaging telemedicine_lambda..."
cd lambdas/telemedicine_lambda
zip -r ../telemedicine_lambda.zip .
cd ../..

# Pharmacy Lambda
echo "Packaging pharmacy_lambda..."
cd lambdas/pharmacy_lambda
zip -r ../pharmacy_lambda.zip .
cd ../..

# PFM Lambda
echo "Packaging pfm_lambda..."
cd lambdas/pfm_lambda
zip -r ../pfm_lambda.zip .
cd ../..

echo "Lambda packaging complete."
Make this script executable: chmod +x scripts/package_lambdas.sh

Implementation Steps:

Install Terraform: If you haven't already, install Terraform: https://developer.hashicorp.com/terraform/downloads

Set up AWS CLI: Configure your AWS CLI with appropriate credentials and default region. Terraform will use these.

Set up FusionAuth:

Deploy a FusionAuth instance (e.g., using Docker, a cloud provider, or their hosted solution).

Create an application within FusionAuth.

Generate an API Key with permissions to POST /api/jwt/validate. For simplicity, you can create a superuser key initially, but narrow down permissions for production.

Note your FusionAuth domain (e.g., https://your-fusionauth.com) and the API Key.

Prepare Lambda Code:

Create the lambdas/ directory and its subdirectories as shown in the structure.

Place the Python code and requirements.txt files into their respective directories.

Run scripts/package_lambdas.sh to create the .zip files for your Lambda functions. You'll need pip installed.

Initialize Terraform:

Bash

terraform init
Plan the Deployment:

Bash

terraform plan -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Replace YOUR_FUSIONAUTH_DOMAIN and YOUR_FUSIONAUTH_API_KEY with your actual FusionAuth details. It's best practice to use a .tfvars file or environment variables for sensitive data rather than passing them directly on the command line for production.

Apply the Configuration:

Bash

terraform apply -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Confirm the apply when prompted.

Test the API:

After terraform apply completes, you will get an api_gateway_base_url output.

You will also get an api_key_value.

To test, you'll need a JWT from FusionAuth. You can obtain one by logging in a user to your FusionAuth application and inspecting network requests, or by using their /oauth2/token endpoint.

Example curl commands:

Login/Session Management (via FusionAuth directly):
This part is handled directly by FusionAuth's OAuth endpoints. Your client application (e.g., web app, mobile app) would interact with FusionAuth for login and session management, receiving a JWT.

Prompt Management:
Prompt management (e.g., password resets, MFA prompts) are also features handled directly by FusionAuth's hosted login pages or APIs that your client application integrates with.

Accessing Microservices:

Bash

# Get the base URL from Terraform output
API_URL=$(terraform output -raw api_gateway_base_url)
API_KEY=$(terraform output -raw api_key_value) # Use this in X-Api-Key header

# Assume you have a JWT_TOKEN obtained from FusionAuth
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Replace with your actual JWT

# Test Payment Service
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "currency": "USD"}' \
  "${API_URL}/prod/payments/charge"

# Test Telemedicine Service
curl -v -X GET \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  "${API_URL}/prod/telemedicine/appointments"

# Test Pharmacy Service
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"prescription_id": "XYZ123"}' \
  "${API_URL}/prod/pharmacy/order"

# Test Personal Health Management Service
curl -v -X PUT \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"weight": 180, "date": "2025-07-16"}' \
  "${API_URL}/prod/personal-health-management/metrics/weight"

# Test Unauthorized Access (without token)
curl -v -X GET "${API_URL}/prod/payments/charge"

# Test Rate Limiting (send many requests quickly with the API_KEY)
# You'll start seeing 429 Too Many Requests errors if you exceed the throttle limits
Clean up (optional):

Bash

terraform destroy -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Explanation of Components and Best Practices:

User Management (FusionAuth):

Login/Session Management/Prompt Management: These are primarily handled by FusionAuth itself. Your client-side applications (web, mobile) would redirect users to FusionAuth for authentication (e.g., via OAuth 2.0 Authorization Code Flow). Upon successful login, FusionAuth issues JWTs.

FusionAuth Custom Authorizer (auth_lambda): This Lambda function is crucial. It's invoked by API Gateway before the request reaches your microservice Lambda. It takes the Authorization header (which should contain a FusionAuth-issued JWT), sends it to FusionAuth's JWT validation endpoint, and based on the response, tells API Gateway whether to Allow or Deny the request.

identity_source and identity_validation_expression: These API Gateway Authorizer settings tell API Gateway where to find the token in the request and provide a basic regex for initial validation.

authorizer_result_ttl_in_seconds: Caches the authorizer's decision, reducing the number of times the authorizer Lambda needs to be invoked, improving performance and reducing cost.

API Gateway Path-based Routing:

We define aws_api_gateway_resource for each top-level microservice path (e.g., payments, telemedicine).

We then use a child resource "{proxy+}" for each of these. This "{proxy+}" greedy path variable allows any sub-path under /payments, /telemedicine, etc., to be routed to the respective Lambda. The Lambda receives the full path and can parse it.

http_method = "ANY" on aws_api_gateway_method means that GET, POST, PUT, DELETE, etc., will all be routed through the same integration.

Response Processing:

Lambda Proxy Integration (type = "AWS_PROXY"): This simplifies response processing significantly. The Lambda function is responsible for returning a JSON object that directly maps to an HTTP response (including statusCode, headers, and body). API Gateway passes this through directly.

API Gateway Gateway Responses (aws_api_gateway_gateway_response): These are used to customize error responses generated by API Gateway itself (e.g., 401 Unauthorized from the authorizer, 400 Bad Request due to validation, 429 Too Many Requests from throttling). We've shown an example for UNAUTHORIZED and BAD_REQUEST_BODY.

Rate Limiting:

API Keys (aws_api_gateway_api_key): Required for associating requests with a usage plan. Clients must send the X-Api-Key header.

Usage Plans (aws_api_gateway_usage_plan): Define throttling rates (requests per second, burst limit) and quotas (total requests over a period).

throttle block: Applied to specific path and HTTP_METHOD combinations within an API stage. The ANY method with /{proxy+} captures all methods and sub-paths for a given microservice.

api_key_required = true: Set on each aws_api_gateway_method to enforce API key usage for that method, enabling usage plan application.

Scalability:

AWS API Gateway: Is a fully managed, highly scalable service by default. It automatically handles scaling to meet demand.

AWS Lambda: Is also highly scalable and serverless. Functions scale automatically based on incoming requests.

aws_api_gateway_deployment triggers: The triggers block ensures that a new API Gateway deployment is created whenever there's a change to the API Gateway resources, methods, or integrations. This is crucial for changes to take effect.

CloudWatch Logging and X-Ray Tracing: Enabled on the aws_api_gateway_stage for monitoring and debugging performance issues, which is vital for understanding and managing scalable systems.

Important Considerations for Production:

Secrets Management: Never hardcode FUSIONAUTH_API_KEY or other sensitive information in your Terraform files or pass them directly as command-line arguments in production. Use AWS Secrets Manager or AWS Systems Manager Parameter Store to securely store and retrieve these values, and grant your Lambda functions IAM permissions to access them.

Domain Names: For a production setup, you would typically configure a custom domain name for your API Gateway (e.g., api.yourdomain.com) using aws_api_gateway_domain_name and aws_api_gateway_base_path_mapping resources, along with an ACM certificate.

Error Handling and Monitoring: Implement robust error handling within your Lambda functions. Set up CloudWatch Alarms for API Gateway metrics (e.g., 4xx, 5xx errors, throttled requests) and Lambda errors/invocations.

CI/CD Pipeline: Automate the terraform plan and terraform apply steps in a CI/CD pipeline.

Modularization (despite the request): While you explicitly asked not to use modules, for a larger microservices architecture, extracting common API Gateway patterns (like resource and method creation for a Lambda proxy) into reusable Terraform modules would greatly improve maintainability, reduce boilerplate, and enforce consistency.

Input Validation: For robust APIs, implement request validation using aws_api_gateway_request_validator and aws_api_gateway_model resources.

CORS: If your frontend application is hosted on a different domain, you'll need to configure CORS for your API Gateway methods. This involves adding OPTIONS methods and specific headers to method_response and integration_response blocks.

VPC Integration: If your Lambda functions or other backend services need to access resources within a VPC (e.g., databases), ensure your Lambdas are configured with VPC settings.

Testing: Comprehensive testing (unit, integration, load, security) is essential before deploying to production.

This Terraform setup provides a strong foundation for your AWS API Gateway and microservices, incorporating the requested features and best practices for a scalable and secure architecture