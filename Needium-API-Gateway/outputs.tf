###########################################################
#Outputs:
#Some parameters that I may need for other use
###########################################################
# outputs.tf

output "api_gateway_base_url" {
  description = "The base URL of the deployed API Gateway."
  value       = aws_api_gateway_deployment.main_deployment.invoke_url
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.main_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client."
  value       = aws_cognito_user_pool_client.main_user_pool_client.id
}

output "cognito_user_pool_domain" {
  description = "The domain for the Cognito User Pool hosted UI (if enabled)."
  value       = aws_cognito_user_pool_domain.main_user_pool_domain.domain
}

output "api_key_value" {
  description = "The value of the generated API Key for rate limiting."
  value       = aws_api_gateway_api_key.default_api_key.value
  sensitive   = true # Mark as sensitive to prevent logging in plain text
}