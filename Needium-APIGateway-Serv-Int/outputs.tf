#############################################################
#Outputs file for the terraform configurations
############################################################
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

output "payment_sqs_queue_url" {
  description = "URL of the Payment SQS Queue"
  value       = aws_sqs_queue.payment_queue.url
}

output "telemedicine_sqs_queue_url" {
  description = "URL of the Telemedicine SQS Queue"
  value       = aws_sqs_queue.telemedicine_queue.url
}

output "pharmacy_alb_dns_name" {
  description = "DNS name of the Pharmacy Application Load Balancer"
  value       = aws_lb.pharmacy_alb.dns_name
}

output "pfm_alb_dns_name" {
  description = "DNS name of the Personal Health Management Application Load Balancer"
  value       = aws_lb.pfm_alb.dns_name
}

output "pharmacy_postgres_db_endpoint" {
  description = "Endpoint of the Pharmacy PostgreSQL RDS instance"
  value       = aws_db_instance.pharmacy_postgres_db.address
}

output "pfm_mssql_db_endpoint" {
  description = "Endpoint of the Personal Health Management MSSQL RDS instance"
  value       = aws_db_instance.pfm_mssql_db.address
}