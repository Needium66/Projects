##################################################################################################
#This project deploys an API Gateway managed Microservices with Fusion Auth as User Authenticator
#It also deploys independent of modules; different from earlier deployment
#It is also powered by Lambda, similar to initial API Gateway deployment
##################################################################################################
#Core Concepts:
#####################

# AWS API Gateway (REST API): Using a REST API to define endpoints and integrate with backend services.

# Path-based Routing: Each microservice will have a distinct base path (e.g., /payments, /telemedicine etc).

# AWS Lambda: Using Lambda functions as the backend for our microservices, invoked by API Gateway.
# Note: The actual Lambda code for each microservice is beyond the scope of this Terraform example, but function resources will be defined.

# FusionAuth: Integration with FusionAuth for authentication will involve a Custom Authorizer Lambda Function that validates JWTs issued by FusionAuth.

# Response Processing: Basic response mapping will be demonstrated.

# Rate Limiting: Implemented using API Gateway usage plans and throttling.

# Scalability: AWS API Gateway is inherently scalable. Configurations will leverage this by defining appropriate settings.
########################################################################################################################################
#Directory Structure:
######################################
# .
# ├── main.tf
# ├── variables.tf
# ├── outputs.tf
# ├── lambdas/
# │   ├── auth_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── payment_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── telemedicine_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   ├── pharmacy_lambda/
# │   │   ├── main.py
# │   │   └── requirements.txt
# │   └── pfm_lambda/
# │       ├── main.py
# │       └── requirements.txt
# └── scripts/
#     └── package_lambdas.sh
################################################################################################
#main.tf:
#It is the Main Terraform Configuration.
#It Defines the AWS API Gateway, Lambda Functions, IAM Roles and their integrations
###############################################################################################
#variables.tf:
#It is the input variables file. It defines the variables for the terraform configuration
###############################################################################################
#outputs.tf:
#It is the outputs file. It enables some resources to be externally provided and reused
###############################################################################################
#Lambda Function Code:
########################################
#Fusion Auth Custom Authorizer: To validate JSON Web Tokens(JWTs) issued by FusionAuth
##############################################################################################
#Lambda Payment Function Code: The Bare Minimum Code for Payment Microservice
##############################################################################################
#Lambda TeleMedicine Function Code: The Bare Minimum Code for Telemedicine Microservice
##############################################################################################
#Lambda Pharmacy Function Code: The Bare Minimum Code for Pharmacy Microservice
################################################################################################
#Lambda Personal Health Management Function Code: The Bare Minimum Code for Payment Microservice
##############################################################################################################################
#Helper Scripts for Lambda Zips: To make templates more efficient by creating zip files for lambda functions with dependencies
#Small, reusable piece of code, to automate tasks within the deployment; to perform repetive actions
##############################################################################################################################
#Implementation Steps:
# Implementation Steps:

# Install Terraform: If you haven't already, install Terraform: https://developer.hashicorp.com/terraform/downloads

# Set up AWS CLI: Configure your AWS CLI with appropriate credentials and default region. Terraform will use these.

# Set up FusionAuth:

# - Deploy a FusionAuth instance (e.g., using Docker, a cloud provider, or their hosted solution).

# - Create an application within FusionAuth.

# - Generate an API Key with permissions to POST /api/jwt/validate. For simplicity, you can create a superuser key initially,
# but narrow down permissions for production.

# - Note your FusionAuth domain (e.g., https://your-fusionauth.com) and the API Key.

# Prepare Lambda Code:

# - Create the lambdas/ directory and its subdirectories as shown in the structure.

# - Place the Python code and requirements.txt files into their respective directories.

# - Run scripts/package_lambdas.sh to create the .zip files for your Lambda functions. You'll need pip installed.
###############################################################################################################################
#Intialize Terraform: 
#terraform init
#########################################
#Plan the Deployment:
#terraform plan -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
#NOTE: Replace YOUR_FUSIONAUTH_DOMAIN and YOUR_FUSIONAUTH_API_KEY with your actual FusionAuth details. It's best practice 
#to use a .tfvars file or environment variables for sensitive data rather than passing them directly on the command line for production
########################################################################################################################################
#Apply the Configuration:
#terraform apply -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
######################################################################################################################
#Test the API:
##########################################################
# After terraform apply completes, you will get an api_gateway_base_url output.

# You will also get an api_key_value.

# To test, you'll need a JWT from FusionAuth. You can obtain one by logging in a user to your FusionAuth application and 
# inspecting network requests, or by using their /oauth2/token endpoint.
#########################################################################################################################
#Curl Commands Examples:
##############################################
# Login/Session Management (via FusionAuth directly):
# This part is handled directly by FusionAuth's OAuth endpoints. Your client application (e.g., web app, mobile app) 
# would interact with FusionAuth for login and session management, receiving a JWT.

# Prompt Management:
# Prompt management (e.g., password resets, MFA prompts) are also features handled directly by FusionAuth's hosted login pages 
# or APIs that your client application integrates with.
###############################################################################################################################
# Get the base URL from Terraform output
# API_URL=$(terraform output -raw api_gateway_base_url)
# API_KEY=$(terraform output -raw api_key_value) # Use this in X-Api-Key header

# # Assume you have a JWT_TOKEN obtained from FusionAuth
# JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Replace with your actual JWT

# # Test Payment Service
# curl -v -X POST \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"amount": 100, "currency": "USD"}' \
#   "${API_URL}/prod/payments/charge"

# # Test Telemedicine Service
# curl -v -X GET \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   "${API_URL}/prod/telemedicine/appointments"

# # Test Pharmacy Service
# curl -v -X POST \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"prescription_id": "XYZ123"}' \
#   "${API_URL}/prod/pharmacy/order"

# # Test Personal Health Management Service
# curl -v -X PUT \
#   -H "Authorization: Bearer ${JWT_TOKEN}" \
#   -H "X-Api-Key: ${API_KEY}" \
#   -H "Content-Type: application/json" \
#   -d '{"weight": 180, "date": "2025-07-16"}' \
#   "${API_URL}/prod/personal-health-management/metrics/weight"

# Test Unauthorized Access (without token)
# curl -v -X GET "${API_URL}/prod/payments/charge"

# Test Rate Limiting (send many requests quickly with the API_KEY)
# You'll start seeing 429 Too Many Requests errors if you exceed the throttle limits
###########################################################################################################################