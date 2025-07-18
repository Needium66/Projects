################################################################################################
#main.tf file for the deployment of the resources for api gateway integration with microservices
################################################################################################
# main.tf

# Configure the GCP provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# --- Networking (VPC, Subnets, Firewall Rules) ---

resource "google_compute_network" "microservices_vpc" {
  name                    = "microservices-vpc"
  auto_create_subnetworks = false # We'll create custom subnets
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.microservices_vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.10.16.0/20"
  region        = var.gcp_region
  network       = google_compute_network.microservices_vpc.id
  private_ip_google_access = true # Required for Cloud Functions to access private services
}

# Firewall rule to allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-microservices"
  network = google_compute_network.microservices_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.10.0.0/16"] # Allow traffic from entire VPC
}

# Firewall rule to allow HTTP/HTTPS from the internet to Load Balancers
resource "google_compute_firewall" "allow_lb_ingress" {
  name    = "allow-lb-ingress"
  network = google_compute_network.microservices_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"] # Allow from all IPs
  target_tags   = ["allow-lb-ingress"] # Apply to resources with this tag
}

# Firewall rule to allow health checks from Load Balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.microservices_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"] # Or your application port
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP health check IP ranges
  target_tags   = ["allow-health-checks"]
}

# Cloud SQL private IP access (Service Networking)
resource "google_compute_network_peering" "private_service_access" {
  name         = "servicenetworking-peer"
  network      = google_compute_network.microservices_vpc.id
  peer_network = "servicenetworking"
  service      = "servicenetworking.googleapis.com"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.microservices_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_address.private_ip_alloc.name]
}

resource "google_compute_address" "private_ip_alloc" {
  name          = "google-managed-services-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.microservices_vpc.id
}

# --- IAM Service Accounts and Permissions ---

# Service Account for Cloud Functions
resource "google_service_account" "cloud_function_sa" {
  account_id   = "cloud-function-sa"
  display_name = "Service Account for Cloud Functions"
}

resource "google_project_iam_member" "cloud_function_invoker" {
  project = var.gcp_project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "cloud_function_runtime" {
  project = var.gcp_project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "cloud_function_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "cloud_function_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

# Permissions for Cloud Functions to access Pub/Sub
resource "google_project_iam_member" "cloud_function_pubsub_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "cloud_function_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

# Permissions for Cloud Functions to access Firestore
resource "google_project_iam_member" "cloud_function_firestore_access" {
  project = var.gcp_project_id
  role    = "roles/datastore.user" # Firestore uses Datastore roles
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

# Service Account for GKE Nodes
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "Service Account for GKE Nodes"
}

resource "google_project_iam_member" "gke_node_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "gke_node_logging_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "gke_node_monitoring_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "gke_node_artifact_registry_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# Service Account for Compute Engine Instances
resource "google_service_account" "compute_engine_sa" {
  account_id   = "compute-engine-sa"
  display_name = "Service Account for Compute Engine Instances"
}

resource "google_project_iam_member" "compute_engine_logging_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compute_engine_sa.email}"
}

resource "google_project_iam_member" "compute_engine_monitoring_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.compute_engine_sa.email}"
}

# --- FusionAuth Integration (API Gateway Extensible Authentication) ---

# Cloud Function for FusionAuth Authorizer
resource "google_cloudfunctions_function" "auth_function" {
  name                  = "fusionauth-authorizer"
  runtime               = "python39"
  entry_point           = "handler"
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.auth_function_zip.name
  trigger_http          = true
  available_memory_mb   = 128
  timeout               = 30
  service_account_email = google_service_account.cloud_function_sa.email
  vpc_connector         = google_vpc_access_connector.connector.id # Connect to VPC
  environment_variables = {
    FUSIONAUTH_DOMAIN  = var.fusionauth_domain
    FUSIONAUTH_API_KEY = var.fusionauth_api_key # Use Secret Manager in production
  }
}

resource "google_storage_bucket" "functions_bucket" {
  name          = "${var.gcp_project_id}-functions-bucket"
  location      = "US" # Multi-region for functions bucket
  force_destroy = true # Be careful with this in production
}

resource "google_storage_bucket_object" "auth_function_zip" {
  bucket = google_storage_bucket.functions_bucket.name
  name   = "auth_function.zip"
  source = data.archive_file.auth_function_zip.output_path
}

data "archive_file" "auth_function_zip" {
  type        = "zip"
  source_dir  = "functions/auth_function"
  output_path = "functions/auth_function.zip"
}

# VPC Access Connector for Cloud Functions to access private services (e.g., FusionAuth, Cloud SQL if needed)
resource "google_vpc_access_connector" "connector" {
  name          = "cloud-functions-connector"
  region        = var.gcp_region
  ip_cidr_range = "10.8.0.0/28" # A small, unused CIDR range within your VPC
  network       = google_compute_network.microservices_vpc.id
}

# --- Payment Microservice (Pub/Sub -> Cloud Function -> Firestore) ---

resource "google_pubsub_topic" "payment_topic" {
  name = "payment-requests-topic"
}

resource "google_pubsub_subscription" "payment_subscription" {
  name  = "payment-processor-subscription"
  topic = google_pubsub_topic.payment_topic.name
  ack_deadline_seconds = 10
  message_retention_duration = "604800s" # 7 days
}

resource "google_cloudfunctions_function" "payment_processor_function" {
  name                  = "payment-processor"
  runtime               = "python39"
  entry_point           = "handler"
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.payment_processor_function_zip.name
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.payment_topic.id
  }
  available_memory_mb   = 256
  timeout               = 60
  service_account_email = google_service_account.cloud_function_sa.email
  vpc_connector         = google_vpc_access_connector.connector.id
  environment_variables = {
    FIRESTORE_COLLECTION_NAME = "payments"
  }
}

resource "google_storage_bucket_object" "payment_processor_function_zip" {
  bucket = google_storage_bucket.functions_bucket.name
  name   = "payment_processor_function.zip"
  source = data.archive_file.payment_processor_function_zip.output_path
}

data "archive_file" "payment_processor_function_zip" {
  type        = "zip"
  source_dir  = "functions/payment_processor_function"
  output_path = "functions/payment_processor_function.zip"
}

resource "google_firestore_database" "payment_firestore_db" {
  project     = var.gcp_project_id
  name        = "(default)" # Default Firestore database
  location_id = "nam5"      # Choose a suitable location
  type        = "FIRESTORE_NATIVE"
}

# --- Telemedicine Microservice (Pub/Sub -> Cloud Function -> Firestore) ---

resource "google_pubsub_topic" "telemedicine_topic" {
  name = "telemedicine-requests-topic"
}

resource "google_pubsub_subscription" "telemedicine_subscription" {
  name  = "telemedicine-processor-subscription"
  topic = google_pubsub_topic.telemedicine_topic.name
  ack_deadline_seconds = 10
  message_retention_duration = "604800s"
}

resource "google_cloudfunctions_function" "telemedicine_processor_function" {
  name                  = "telemedicine-processor"
  runtime               = "python39"
  entry_point           = "handler"
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.telemedicine_processor_function_zip.name
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.telemedicine_topic.id
  }
  available_memory_mb   = 256
  timeout               = 60
  service_account_email = google_service_account.cloud_function_sa.email
  vpc_connector         = google_vpc_access_connector.connector.id
  environment_variables = {
    FIRESTORE_COLLECTION_NAME = "telemedicine_appointments"
  }
}

resource "google_storage_bucket_object" "telemedicine_processor_function_zip" {
  bucket = google_storage_bucket.functions_bucket.name
  name   = "telemedicine_processor_function.zip"
  source = data.archive_file.telemedicine_processor_function_zip.output_path
}

data "archive_file" "telemedicine_processor_function_zip" {
  type        = "zip"
  source_dir  = "functions/telemedicine_processor_function"
  output_path = "functions/telemedicine_processor_function.zip"
}

# Re-using the same default Firestore database for simplicity, but could be separate
# resource "google_firestore_database" "telemedicine_firestore_db" { ... }

# --- Pharmacy Services (Load Balancer -> GKE -> PostgreSQL) ---

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "pharmacy_postgres_db" {
  database_version = "POSTGRES_13"
  name             = "pharmacy-postgres-db"
  region           = var.gcp_region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false # Disable public IP
      private_network = google_compute_network.microservices_vpc.id
      require_ssl     = true
    }
  }
  root_password = var.db_password # Use Secret Manager in production
  depends_on    = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "pharmacy_db_name" {
  name     = "pharmacy_db"
  instance = google_sql_database_instance.pharmacy_postgres_db.name
}

resource "google_sql_user" "pharmacy_db_user" {
  name     = var.db_username
  instance = google_sql_database_instance.pharmacy_postgres_db.name
  host     = "%" # Allow connections from any host (within VPC)
  password = var.db_password
}

# GKE Cluster
resource "google_container_cluster" "pharmacy_gke_cluster" {
  name               = "pharmacy-gke-cluster"
  location           = var.gcp_region
  initial_node_count = 1
  network            = google_compute_network.microservices_vpc.id
  subnetwork         = google_compute_subnetwork.private_subnet.id
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  release_channel {
    channel = "REGULAR"
  }
  node_config {
    machine_type = "e2-medium"
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Broad scope, refine for production
    ]
    tags = ["allow-health-checks", "allow-internal-microservices"]
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Access master endpoint via internal IP
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "VPC Access"
      cidr_block   = google_compute_network.microservices_vpc.ip_cidr_range
    }
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block   = "/19"
    services_ipv4_cidr_block  = "/22"
    cluster_secondary_range_name = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  depends_on = [
    google_project_iam_member.gke_node_compute_viewer,
    google_project_iam_member.gke_node_logging_writer,
    google_project_iam_member.gke_node_monitoring_writer,
    google_project_iam_member.gke_node_artifact_registry_reader
  ]
}

# GKE Node Pool
resource "google_container_node_pool" "pharmacy_node_pool" {
  name       = "pharmacy-node-pool"
  cluster    = google_container_cluster.pharmacy_gke_cluster.name
  location   = var.gcp_region
  node_count = 1
  node_config {
    machine_type    = "e2-medium"
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["allow-health-checks", "allow-internal-microservices"]
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Cloud Load Balancer for Pharmacy GKE
resource "google_compute_url_map" "pharmacy_url_map" {
  name            = "pharmacy-url-map"
  default_service = google_compute_backend_service.pharmacy_backend_service.id
}

resource "google_compute_backend_service" "pharmacy_backend_service" {
  name        = "pharmacy-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  health_checks = [google_compute_health_check.pharmacy_health_check.id]

  # Target the GKE NodePort service, assuming your GKE app exposes a NodePort
  # In a real scenario, you'd deploy your app to GKE and expose it via a Service
  # and potentially an Ingress. For Terraform, we target the nodes directly.
  # This assumes your GKE app is listening on port 80 or a NodePort.
  # For GKE, the backend type is typically 'NEG' (Network Endpoint Group)
  # but for simplicity and "no modules", we'll target instance group.
  # This requires a managed instance group for the GKE nodes.
  # GKE creates managed instance groups for its node pools.
  backend {
    group = google_container_node_pool.pharmacy_node_pool.instance_group_urls[0]
  }
}

resource "google_compute_health_check" "pharmacy_health_check" {
  name               = "pharmacy-health-check"
  request_path       = "/" # Your application's health check endpoint
  port               = 80 # Your application's port
  check_interval_sec = 5
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold  = 2
}

resource "google_compute_target_http_proxy" "pharmacy_http_proxy" {
  name    = "pharmacy-http-proxy"
  url_map = google_compute_url_map.pharmacy_url_map.id
}

resource "google_compute_global_forwarding_rule" "pharmacy_forwarding_rule" {
  name        = "pharmacy-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.pharmacy_http_proxy.id
  load_balancing_scheme = "EXTERNAL"
}

# --- Personal Health Management Services (Load Balancer -> Compute Engine -> MSSQL) ---

# Cloud SQL MSSQL Instance
resource "google_sql_database_instance" "pfm_mssql_db" {
  database_version = "SQLSERVER_2017_EXPRESS" # Or other versions
  name             = "pfm-mssql-db"
  region           = var.gcp_region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.microservices_vpc.id
      require_ssl     = true
    }
  }
  root_password = var.db_password # Use Secret Manager in production
  depends_on    = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "pfm_db_name" {
  name     = "pfm_db"
  instance = google_sql_database_instance.pfm_mssql_db.name
}

resource "google_sql_user" "pfm_db_user" {
  name     = var.db_username
  instance = google_sql_database_instance.pfm_mssql_db.name
  host     = "%" # Allow connections from any host (within VPC)
  password = var.db_password
}

# Compute Engine Instance Group for PFM
resource "google_compute_instance_template" "pfm_instance_template" {
  name         = "pfm-instance-template"
  machine_type = "e2-medium"
  tags         = ["allow-health-checks", "allow-lb-ingress", "allow-internal-microservices"] # Apply firewall tags

  disk {
    source_image = "debian-cloud/debian-11" # Or a Windows Server image for MSSQL
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.microservices_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No public IP, traffic comes through internal load balancer
  }

  service_account {
    email  = google_service_account.compute_engine_sa.email
    scopes = ["cloud-platform"] # Broad scope, refine for production
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "Hello from Personal Health Management EC2!" | sudo tee /var/www/html/index.html
    # In a real scenario, you would install your MSSQL application here
    # For Windows, this would be a PowerShell script.
  EOF
}

resource "google_compute_instance_group_manager" "pfm_mig" {
  name               = "pfm-mig"
  zone               = "${var.gcp_region}-b" # Pick a zone
  base_instance_name = "pfm-instance"
  target_size        = 1 # Start with 1 instance
  version {
    instance_template = google_compute_instance_template.pfm_instance_template.id
  }
  named_port {
    name = "http"
    port = 80
  }
}

# Cloud Load Balancer for PFM Compute Engine
resource "google_compute_url_map" "pfm_url_map" {
  name            = "pfm-url-map"
  default_service = google_compute_backend_service.pfm_backend_service.id
}

resource "google_compute_backend_service" "pfm_backend_service" {
  name        = "pfm-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  health_checks = [google_compute_health_check.pfm_health_check.id]
  backend {
    group = google_compute_instance_group_manager.pfm_mig.instance_group
  }
}

resource "google_compute_health_check" "pfm_health_check" {
  name               = "pfm-health-check"
  request_path       = "/"
  port               = 80
  check_interval_sec = 5
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold  = 2
}

resource "google_compute_target_http_proxy" "pfm_http_proxy" {
  name    = "pfm-http-proxy"
  url_map = google_compute_url_map.pfm_url_map.id
}

resource "google_compute_global_forwarding_rule" "pfm_forwarding_rule" {
  name        = "pfm-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.pfm_http_proxy.id
  load_balancing_scheme = "EXTERNAL"
}

# --- GCP API Gateway Configuration ---

# API Gateway API resource
resource "google_api_gateway_api" "microservices_api_gw" {
  api_id      = "microservices-api"
  display_name = "Microservices API Gateway"
}

# API Gateway Config (OpenAPI Specification)
resource "google_api_gateway_api_config" "microservices_api_config" {
  api_config_id = "microservices-api-config"
  api           = google_api_gateway_api.microservices_api_gw.api_id
  display_name  = "Microservices API Config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(templatefile("${path.module}/openapi.yaml", {
        auth_function_url            = google_cloudfunctions_function.auth_function.url
        payment_pubsub_topic_name    = google_pubsub_topic.payment_topic.name
        telemedicine_pubsub_topic_name = google_pubsub_topic.telemedicine_topic.name
        pharmacy_alb_ip              = google_compute_global_forwarding_rule.pharmacy_forwarding_rule.ip_address
        pfm_alb_ip                   = google_compute_global_forwarding_rule.pfm_forwarding_rule.ip_address
        gcp_project_id               = var.gcp_project_id
        gcp_region                   = var.gcp_region
      }))
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Gateway (Deployment)
resource "google_api_gateway_gateway" "microservices_gateway" {
  gateway_id = "microservices-gateway"
  api_config = google_api_gateway_api_config.microservices_api_config.id
  region     = var.gcp_region
}

# Enable necessary GCP services for API Gateway
resource "google_project_service" "api_gateway_service" {
  project = var.gcp_project_id
  service = "apigateway.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run_service" { # API Gateway uses Cloud Run internally
  project = var.gcp_project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions_service" {
  project = var.gcp_project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub_service" {
  project = var.gcp_project_id
  service = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore_service" {
  project = var.gcp_project_id
  service = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_service" {
  project = var.gcp_project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql_admin_service" {
  project = var.gcp_project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_service" {
  project = var.gcp_project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_service" {
  project = var.gcp_project_id
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess_service" {
  project = var.gcp_project_id
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}