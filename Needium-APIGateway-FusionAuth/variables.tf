#########################################################
#Variables:
########################################################
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-2"
}

variable "needium_fusionauth_domain" {
  description = "The domain name of your FusionAuth instance (e.g., https://your-fusionauth-instance.com)"
  type        = string
  sensitive   = true
}

variable "needium_fusionauth_api_key" {
  description = "The API Key for your FusionAuth instance. Used by the custom authorizer to validate tokens."
  type        = string
  sensitive   = true
}