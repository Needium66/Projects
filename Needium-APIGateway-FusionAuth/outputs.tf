#############################################################
#Outputs File:
#############################################################
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