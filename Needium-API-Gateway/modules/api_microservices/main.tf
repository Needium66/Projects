############################################################
#Main file in modules
############################################################
# modules/api_microservice/main.tf

resource "aws_api_gateway_resource" "service_resource" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_resource_id
  path_part   = var.path_part
}

resource "aws_api_gateway_method" "service_method_post" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.service_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS" # Secure with Cognito Authorizer
  authorizer_id = var.authorizer_id
  api_key_required = true # Require API Key for rate limiting
}

resource "aws_api_gateway_integration" "service_integration_post" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.service_resource.id
  http_method             = aws_api_gateway_method.service_method_post.http_method
  integration_http_method = "POST" # Lambda expects POST
  type                    = "AWS_PROXY" # Simple proxy to Lambda
  uri                     = var.lambda_arn
}

resource "aws_api_gateway_method" "service_method_get" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.service_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS" # Secure with Cognito Authorizer
  authorizer_id = var.authorizer_id
  api_key_required = true # Require API Key for rate limiting
}

resource "aws_api_gateway_integration" "service_integration_get" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.service_resource.id
  http_method             = aws_api_gateway_method.service_method_get.http_method
  integration_http_method = "GET" # Lambda expects GET
  type                    = "AWS_PROXY" # Simple proxy to Lambda
  uri                     = var.lambda_arn
}

# Output the resource ID for the main_deployment trigger
output "resource_id" {
  value = aws_api_gateway_resource.service_resource.id
}

# variables.tf for the module
variable "rest_api_id" {
  description = "The ID of the parent REST API."
  type        = string
}

variable "parent_resource_id" {
  description = "The ID of the parent resource (e.g., root resource ID)."
  type        = string
}

variable "path_part" {
  description = "The path part for this microservice resource."
  type        = string
}

variable "lambda_arn" {
  description = "The ARN of the Lambda function to integrate with."
  type        = string
}

variable "authorizer_id" {
  description = "The ID of the Cognito Authorizer."
  type        = string
}

variable "project_name" {
  description = "The project name for tagging."
  type        = string
}