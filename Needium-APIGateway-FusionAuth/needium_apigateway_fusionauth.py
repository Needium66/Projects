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


Directory Structure:

.
├── main.tf
├── variables.tf
├── outputs.tf
├── lambdas/
│   ├── auth_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── payment_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── telemedicine_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── pharmacy_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   └── pfm_lambda/
│       ├── main.py
│       └── requirements.txt
└── scripts/
    └── package_lambdas.sh
1. main.tf - Main Terraform Configuration



5. scripts/package_lambdas.sh (Helper Script for Lambda Zips)

Bash

#!/bin/bash
set -e

# This script creates zip files for Lambda functions with their dependencies.
# In a real CI/CD pipeline, this would be automated more robustly.

# Auth Lambda
echo "Packaging auth_lambda..."
cd lambdas/auth_lambda
pip install -r requirements.txt -t .
zip -r ../auth_lambda.zip .
rm -rf lib python *.dist-info # Clean up downloaded packages
cd ../..

# Payment Lambda
echo "Packaging payment_lambda..."
cd lambdas/payment_lambda
# No requirements.txt for this example, but if there were:
# pip install -r requirements.txt -t .
zip -r ../payment_lambda.zip .
cd ../..

# Telemedicine Lambda
echo "Packaging telemedicine_lambda..."
cd lambdas/telemedicine_lambda
zip -r ../telemedicine_lambda.zip .
cd ../..

# Pharmacy Lambda
echo "Packaging pharmacy_lambda..."
cd lambdas/pharmacy_lambda
zip -r ../pharmacy_lambda.zip .
cd ../..

# PFM Lambda
echo "Packaging pfm_lambda..."
cd lambdas/pfm_lambda
zip -r ../pfm_lambda.zip .
cd ../..

echo "Lambda packaging complete."
Make this script executable: chmod +x scripts/package_lambdas.sh

Implementation Steps:

Install Terraform: If you haven't already, install Terraform: https://developer.hashicorp.com/terraform/downloads

Set up AWS CLI: Configure your AWS CLI with appropriate credentials and default region. Terraform will use these.

Set up FusionAuth:

Deploy a FusionAuth instance (e.g., using Docker, a cloud provider, or their hosted solution).

Create an application within FusionAuth.

Generate an API Key with permissions to POST /api/jwt/validate. For simplicity, you can create a superuser key initially, 
but narrow down permissions for production.

Note your FusionAuth domain (e.g., https://your-fusionauth.com) and the API Key.

Prepare Lambda Code:

Create the lambdas/ directory and its subdirectories as shown in the structure.

Place the Python code and requirements.txt files into their respective directories.

Run scripts/package_lambdas.sh to create the .zip files for your Lambda functions. You'll need pip installed.

Initialize Terraform:

Bash

terraform init
Plan the Deployment:

Bash

terraform plan -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Replace YOUR_FUSIONAUTH_DOMAIN and YOUR_FUSIONAUTH_API_KEY with your actual FusionAuth details. It's best practice to use a .tfvars file or environment variables for sensitive data rather than passing them directly on the command line for production.

Apply the Configuration:

Bash

terraform apply -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Confirm the apply when prompted.

Test the API:

After terraform apply completes, you will get an api_gateway_base_url output.

You will also get an api_key_value.

To test, you'll need a JWT from FusionAuth. You can obtain one by logging in a user to your FusionAuth application and 
inspecting network requests, or by using their /oauth2/token endpoint.

Example curl commands:

Login/Session Management (via FusionAuth directly):
This part is handled directly by FusionAuth's OAuth endpoints. Your client application (e.g., web app, mobile app) would interact 
with FusionAuth for login and session management, receiving a JWT.

Prompt Management:
Prompt management (e.g., password resets, MFA prompts) are also features handled directly by FusionAuth's hosted login pages or 
APIs that your client application integrates with.

Accessing Microservices:

Bash

# Get the base URL from Terraform output
API_URL=$(terraform output -raw api_gateway_base_url)
API_KEY=$(terraform output -raw api_key_value) # Use this in X-Api-Key header

# Assume you have a JWT_TOKEN obtained from FusionAuth
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Replace with your actual JWT

# Test Payment Service
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "currency": "USD"}' \
  "${API_URL}/prod/payments/charge"

# Test Telemedicine Service
curl -v -X GET \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  "${API_URL}/prod/telemedicine/appointments"

# Test Pharmacy Service
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"prescription_id": "XYZ123"}' \
  "${API_URL}/prod/pharmacy/order"

# Test Personal Health Management Service
curl -v -X PUT \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"weight": 180, "date": "2025-07-16"}' \
  "${API_URL}/prod/personal-health-management/metrics/weight"

# Test Unauthorized Access (without token)
curl -v -X GET "${API_URL}/prod/payments/charge"

# Test Rate Limiting (send many requests quickly with the API_KEY)
# You'll start seeing 429 Too Many Requests errors if you exceed the throttle limits
Clean up (optional):

Bash

terraform destroy -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY"
Explanation of Components and Best Practices:

User Management (FusionAuth):

Login/Session Management/Prompt Management: These are primarily handled by FusionAuth itself. Your client-side applications 
(web, mobile) would redirect users to FusionAuth for authentication (e.g., via OAuth 2.0 Authorization Code Flow). 
Upon successful login, FusionAuth issues JWTs.

FusionAuth Custom Authorizer (auth_lambda): This Lambda function is crucial. It's invoked by API Gateway before the request reaches your
microservice Lambda. It takes the Authorization header (which should contain a FusionAuth-issued JWT), sends it to FusionAuth's 
JWT validation endpoint, and based on the response, tells API Gateway whether to Allow or Deny the request.

identity_source and identity_validation_expression: These API Gateway Authorizer settings tell API Gateway where to find the token in
 the request and provide a basic regex for initial validation.

authorizer_result_ttl_in_seconds: Caches the authorizer's decision, reducing the number of times the authorizer Lambda needs to be
invoked, improving performance and reducing cost.

API Gateway Path-based Routing:

Define aws_api_gateway_resource for each top-level microservice path (e.g., payments, telemedicine).

Then use a child resource "{proxy+}" for each of these. This "{proxy+}" greedy path variable allows any sub-path under
/payments, /telemedicine, etc., to be routed to the respective Lambda. The Lambda receives the full path and can parse it.

http_method = "ANY" on aws_api_gateway_method means that GET, POST, PUT, DELETE, etc., will all be routed through the same integration.

Response Processing:

Lambda Proxy Integration (type = "AWS_PROXY"): This simplifies response processing significantly. The Lambda function is responsible
for returning a JSON object that directly maps to an HTTP response (including statusCode, headers, and body). API Gateway passes this
through directly.

API Gateway Gateway Responses (aws_api_gateway_gateway_response): These are used to customize error responses generated by API Gateway
itself (e.g., 401 Unauthorized from the authorizer, 400 Bad Request due to validation, 429 Too Many Requests from throttling). 
An example for UNAUTHORIZED and BAD_REQUEST_BODY is shown

Rate Limiting:

API Keys (aws_api_gateway_api_key): Required for associating requests with a usage plan. Clients must send the X-Api-Key header.

Usage Plans (aws_api_gateway_usage_plan): Define throttling rates (requests per second, burst limit) and quotas (total requests over
a period).

throttle block: Applied to specific path and HTTP_METHOD combinations within an API stage. The ANY method with /{proxy+} captures all
methods and sub-paths for a given microservice.

api_key_required = true: Set on each aws_api_gateway_method to enforce API key usage for that method, enabling usage plan application.

Scalability:

AWS API Gateway: Is a fully managed, highly scalable service by default. It automatically handles scaling to meet demand.

AWS Lambda: Is also highly scalable and serverless. Functions scale automatically based on incoming requests.

aws_api_gateway_deployment triggers: The triggers block ensures that a new API Gateway deployment is created whenever there's a change
to the API Gateway resources, methods, or integrations. This is crucial for changes to take effect.

CloudWatch Logging and X-Ray Tracing: Enabled on the aws_api_gateway_stage for monitoring and debugging performance issues, which is 
vital for understanding and managing scalable systems.

Important Considerations for Production:

Secrets Management: Never hardcode FUSIONAUTH_API_KEY or other sensitive information in your Terraform files or pass them directly as
command-line arguments in production. Use AWS Secrets Manager or AWS Systems Manager Parameter Store to securely store and retrieve
these values, and grant your Lambda functions IAM permissions to access them.

Domain Names: For a production setup, you would typically configure a custom domain name for your API Gateway (e.g., api.yourdomain.com)
using aws_api_gateway_domain_name and aws_api_gateway_base_path_mapping resources, along with an ACM certificate.

Error Handling and Monitoring: Implement robust error handling within your Lambda functions. Set up CloudWatch Alarms for API Gateway
metrics (e.g., 4xx, 5xx errors, throttled requests) and Lambda errors/invocations.

CI/CD Pipeline: Automate the terraform plan and terraform apply steps in a CI/CD pipeline.

Modularization (despite the request): While you explicitly asked not to use modules, for a larger microservices architecture, extracting
common API Gateway patterns (like resource and method creation for a Lambda proxy) into reusable Terraform modules would greatly improve
maintainability, reduce boilerplate, and enforce consistency.

Input Validation: For robust APIs, implement request validation using aws_api_gateway_request_validator and aws_api_gateway_model
resources.

CORS: If your frontend application is hosted on a different domain, you'll need to configure CORS for your API Gateway methods.
This involves adding OPTIONS methods and specific headers to method_response and integration_response blocks.

VPC Integration: If your Lambda functions or other backend services need to access resources within a VPC (e.g., databases),
ensure your Lambdas are configured with VPC settings.

Testing: Comprehensive testing (unit, integration, load, security) is essential before deploying to production.

This Terraform setup provides a strong foundation for your AWS API Gateway and microservices, incorporating the requested features
and best practices for a scalable and secure architecture