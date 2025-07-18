########################################################################
#outputs.tf file
########################################################################
# outputs.tf

output "api_gateway_url" {
  description = "The base URL of the deployed GCP API Gateway"
  value       = google_api_gateway_gateway.microservices_gateway.default_hostname
}

output "pharmacy_alb_ip" {
  description = "The IP address of the Pharmacy Service Load Balancer"
  value       = google_compute_global_forwarding_rule.pharmacy_forwarding_rule.ip_address
}

output "pfm_alb_ip" {
  description = "The IP address of the Personal Health Management Service Load Balancer"
  value       = google_compute_global_forwarding_rule.pfm_forwarding_rule.ip_address
}

output "pharmacy_postgres_db_connection_name" {
  description = "Connection name for Pharmacy PostgreSQL Cloud SQL instance"
  value       = google_sql_database_instance.pharmacy_postgres_db.connection_name
}

output "pfm_mssql_db_connection_name" {
  description = "Connection name for Personal Health Management MSSQL Cloud SQL instance"
  value       = google_sql_database_instance.pfm_mssql_db.connection_name
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster for Pharmacy service"
  value       = google_container_cluster.pharmacy_gke_cluster.name
}

output "gke_cluster_location" {
  description = "Location of the GKE cluster for Pharmacy service"
  value       = google_container_cluster.pharmacy_gke_cluster.location
}