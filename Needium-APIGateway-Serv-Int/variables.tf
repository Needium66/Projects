################################################################
#Variables file for the terraform configurations
################################################################
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

variable "db_username" {
  description = "Username for the RDS databases."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password for the RDS databases."
  type        = string
  sensitive   = true
}

variable "ec2_key_pair_name" {
  description = "Optional: Name of an existing EC2 Key Pair for SSH access to EC2 instance."
  type        = string
  default     = "" # Leave empty if not using SSH key
}