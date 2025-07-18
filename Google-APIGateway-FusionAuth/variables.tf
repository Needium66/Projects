################################################################
#variables file
###############################################################
# variables.tf

variable "gcp_project_id" {
  description = "Your GCP Project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources into."
  type        = string
  default     = "us-central1" # Example region
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
  description = "Username for the Cloud SQL databases."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password for the Cloud SQL databases."
  type        = string
  sensitive   = true
}