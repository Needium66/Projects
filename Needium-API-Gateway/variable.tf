##########################################################
#Variables
##########################################################
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "us-east-2" # Ohio
}

variable "project_name" {
  description = "A unique name for your project, used as a prefix for resources."
  type        = string
  default     = "HealthcareMicroservices"
}

variable "cognito_user_pool_name" {
  description = "Name for the Cognito User Pool."
  type        = string
  default     = "HealthcareUserPool"
}

variable "api_gateway_name" {
  description = "Name for the API Gateway REST API."
  type        = string
  default     = "HealthcareAPI"
}

variable "api_gateway_stage_name" {
  description = "Name for the API Gateway deployment stage."
  type    = string
  default = "prod"
}

variable "default_rate_limit_burst" {
  description = "The maximum burst for the default API Gateway usage plan."
  type        = number
  default     = 100
}

variable "default_rate_limit_rate" {
  description = "The steady-state rate for the default API Gateway usage plan (requests per second)."
  type        = number
  default     = 50
}