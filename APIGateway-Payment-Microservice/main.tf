######################################
#main.tf file
######################################
# main.tf

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2" # Or your preferred AWS region
}

# -----------------------------------------------------------------------------
# 1. IAM Roles and Policies
# -----------------------------------------------------------------------------

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "payment-service-lambda-role"

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
}

# IAM Policy for Lambda to write logs to CloudWatch
resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
  name = "payment-service-lambda-cloudwatch-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for Payment Processor Lambda to access DynamoDB
resource "aws_iam_role_policy" "payment_processor_dynamodb_policy" {
  name = "payment-processor-dynamodb-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan", # For simplicity in example, use Query with GSI in production
          "dynamodb:UpdateItem"
        ],
        Effect = "Allow",
        Resource = aws_dynamodb_table.payments_table.arn
      }
    ]
  })
}

# IAM Policy for Payment Processor Lambda to send messages to SQS
resource "aws_iam_role_policy" "payment_processor_sqs_policy" {
  name = "payment-processor-sqs-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:SendMessage"
        ],
        Effect = "Allow",
        Resource = aws_sqs_queue.payment_queue.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# 2. DynamoDB Table
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "payments_table" {
  name         = "payments"
  billing_mode = "PAY_PER_REQUEST" # On-demand capacity

  hash_key = "paymentId"

  attribute {
    name = "paymentId"
    type = "S"
  }

  tags = {
    Name        = "PaymentsTable"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# -----------------------------------------------------------------------------
# 3. SQS Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "payment_queue" {
  name                       = "payment-processing-queue"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30 # Default visibility timeout

  tags = {
    Name        = "PaymentProcessingQueue"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# -----------------------------------------------------------------------------
# 4. Lambda Functions
# -----------------------------------------------------------------------------

# Create zip file for FusionAuth Authorizer Lambda code
resource "local_file" "lambda_authorizer_zip" {
  content  = file("${path.module}/lambda_authorizer.py") # Assumes lambda_authorizer.py is in the same directory
  filename = "lambda_authorizer.zip"
  # This is a simplification. In a real scenario, you'd use a data source like
  # data "archive_file" "lambda_authorizer_zip" {
  #   type        = "zip"
  #   source_file = "${path.module}/lambda_authorizer.py"
  #   output_path = "lambda_authorizer.zip"
  # }
  # and then reference output_path. This approach directly uses a local file.
}

# FusionAuth Custom Authorizer Lambda
resource "aws_lambda_function" "fusionauth_authorizer_lambda" {
  function_name    = "FusionAuthCustomAuthorizer"
  handler          = "lambda_authorizer.lambda_handler"
  runtime          = "python3.9" # Or a newer Python version
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = local_file.lambda_authorizer_zip.filename
  source_code_hash = filebase64sha256(local_file.lambda_authorizer_zip.filename)
  timeout          = 30 # Max 30 seconds for authorizer
  memory_size      = 128

  environment {
    variables = {
      # IMPORTANT: Replace with your actual FusionAuth details
      FUSIONAUTH_TENANT_ID = "YOUR_FUSIONAUTH_TENANT_ID"
      FUSIONAUTH_ISSUER    = "https://your-fusionauth-domain.com"
      FUSIONAUTH_JWKS_URL  = "https://your-fusionauth-domain.com/.well-known/jwks.json"
    }
  }

  tags = {
    Name        = "FusionAuthAuthorizer"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# Create zip file for Payment Processor Lambda code
resource "local_file" "lambda_payment_processor_zip" {
  content  = file("${path.module}/payment_processor.py") # Assumes payment_processor.py is in the same directory
  filename = "payment_processor.zip"
  # Same simplification as above for local_file.
}

# Payment Processor Lambda
resource "aws_lambda_function" "payment_processor_lambda" {
  function_name    = "PaymentProcessorService"
  handler          = "payment_processor.lambda_handler"
  runtime          = "python3.9" # Or a newer Python version
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = local_file.lambda_payment_processor_zip.filename
  source_code_hash = filebase64sha256(local_file.lambda_payment_processor_zip.filename)
  timeout          = 60 # Allow more time for processing
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.payments_table.name
      SQS_QUEUE_URL       = aws_sqs_queue.payment_queue.id # Use ID for URL
    }
  }

  tags = {
    Name        = "PaymentProcessor"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# -----------------------------------------------------------------------------
# 5. API Gateway
# -----------------------------------------------------------------------------

# API Gateway REST API
resource "aws_api_gateway_rest_api" "payment_api_gateway" {
  name        = "PaymentServiceAPI"
  description = "API Gateway for Payment Microservices"

  endpoint_configuration {
    types = ["REGIONAL"] # Or "EDGE" for CloudFront distribution
  }

  tags = {
    Name        = "PaymentServiceAPI"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "fusionauth_authorizer" {
  name                   = "FusionAuthAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.payment_api_gateway.id
  type                   = "TOKEN" # Or "REQUEST" if you need more context
  authorizer_uri         = aws_lambda_function.fusionauth_authorizer_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.lambda_execution_role.arn # Role for API Gateway to invoke Lambda
  identity_source        = "method.request.header.Authorization"
  # Token validation result caching (optional, but good for performance)
  authorizer_result_ttl_in_seconds = 300 # Cache for 5 minutes
}

# Permission for API Gateway to invoke the Authorizer Lambda
resource "aws_lambda_permission" "api_gateway_authorizer_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fusionauth_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* part is crucial to allow invocation from any method/path within the API
  source_arn = "${aws_api_gateway_rest_api.payment_api_gateway.execution_arn}/*/*"
}


# API Gateway Resource: /payments
resource "aws_api_gateway_resource" "payments_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.payment_api_gateway.root_resource_id
  path_part   = "payments"
}

# API Gateway Resource: /payments/{paymentId}
resource "aws_api_gateway_resource" "payment_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api_gateway.id
  parent_id   = aws_api_gateway_resource.payments_resource.id
  path_part   = "{paymentId}"
}

# API Gateway Method: POST /payments (Create Payment)
resource "aws_api_gateway_method" "post_payments_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id   = aws_api_gateway_resource.payments_resource.id
  http_method   = "POST"
  authorization = "CUSTOM" # Use custom authorizer
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
}

# API Gateway Integration: POST /payments to Payment Processor Lambda
resource "aws_api_gateway_integration" "post_payments_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id             = aws_api_gateway_resource.payments_resource.id
  http_method             = aws_api_gateway_method.post_payments_method.http_method
  integration_http_method = "POST" # Lambda Proxy integration uses POST
  type                    = "AWS_PROXY" # Lambda Proxy integration
  uri                     = aws_lambda_function.payment_processor_lambda.invoke_arn
}

# API Gateway Method: GET /payments (List Payments)
resource "aws_api_gateway_method" "get_payments_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id   = aws_api_gateway_resource.payments_resource.id
  http_method   = "GET"
  authorization = "CUSTOM" # Use custom authorizer
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
}

# API Gateway Integration: GET /payments to Payment Processor Lambda
resource "aws_api_gateway_integration" "get_payments_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id             = aws_api_gateway_resource.payments_resource.id
  http_method             = aws_api_gateway_method.get_payments_method.http_method
  integration_http_method = "POST" # Lambda Proxy integration uses POST
  type                    = "AWS_PROXY" # Lambda Proxy integration
  uri                     = aws_lambda_function.payment_processor_lambda.invoke_arn
}

# API Gateway Method: GET /payments/{paymentId} (Get Single Payment)
resource "aws_api_gateway_method" "get_payment_by_id_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id   = aws_api_gateway_resource.payment_id_resource.id
  http_method   = "GET"
  authorization = "CUSTOM" # Use custom authorizer
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id

  request_parameters = {
    "method.request.path.paymentId" = true # Mark path parameter as required
  }
}

# API Gateway Integration: GET /payments/{paymentId} to Payment Processor Lambda
resource "aws_api_gateway_integration" "get_payment_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api_gateway.id
  resource_id             = aws_api_gateway_resource.payment_id_resource.id
  http_method             = aws_api_gateway_method.get_payment_by_id_method.http_method
  integration_http_method = "POST" # Lambda Proxy integration uses POST
  type                    = "AWS_PROXY" # Lambda Proxy integration
  uri                     = aws_lambda_function.payment_processor_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.paymentId" = "method.request.path.paymentId" # Map path parameter
  }
}

# Permission for API Gateway to invoke the Payment Processor Lambda
resource "aws_lambda_permission" "api_gateway_payment_processor_permission" {
  statement_id  = "AllowAPIGatewayInvokePaymentProcessor"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processor_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* part is crucial to allow invocation from any method/path within the API
  source_arn = "${aws_api_gateway_rest_api.payment_api_gateway.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "payment_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.payment_api_gateway.id

  # This ensures a new deployment is created when any API Gateway resource changes
  # (methods, integrations, resources).
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.payments_resource.id,
      aws_api_gateway_resource.payment_id_resource.id,
      aws_api_gateway_method.post_payments_method.id,
      aws_api_gateway_integration.post_payments_integration.id,
      aws_api_gateway_method.get_payments_method.id,
      aws_api_gateway_integration.get_payments_integration.id,
      aws_api_gateway_method.get_payment_by_id_method.id,
      aws_api_gateway_integration.get_payment_by_id_integration.id,
      aws_api_gateway_authorizer.fusionauth_authorizer.id # Include authorizer in triggers
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "dev_stage" {
  deployment_id = aws_api_gateway_deployment.payment_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.payment_api_gateway.id
  stage_name    = "dev" # Or "prod", "staging"
  description   = "Development stage for Payment Service API"

  variables = {
    # Example stage variables if needed by Lambdas
    LOG_LEVEL = "INFO"
  }

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
      authorizerError         = "$context.authorizer.error",
      authorizerPrincipalId   = "$context.authorizer.principalId"
    })
  }

  tags = {
    Name        = "PaymentServiceDevStage"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.payment_api_gateway.name}/dev"
  retention_in_days = 7 # Retain logs for 7 days

  tags = {
    Name        = "APIGatewayAccessLogs"
    Environment = "dev"
    Service     = "PaymentService"
  }
}

# Output the API Gateway invoke URL
output "api_gateway_invoke_url" {
  description = "The invoke URL for the Payment Service API Gateway"
  value       = "${aws_api_gateway_deployment.payment_api_deployment.invoke_url}/${aws_api_gateway_stage.dev_stage.stage_name}"
}

output "payment_processor_lambda_name" {
  description = "Name of the Payment Processor Lambda function"
  value       = aws_lambda_function.payment_processor_lambda.function_name
}

output "fusionauth_authorizer_lambda_name" {
  description = "Name of the FusionAuth Authorizer Lambda function"
  value       = aws_lambda_function.fusionauth_authorizer_lambda.function_name
}

