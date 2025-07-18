Directory Structure:

.
├── main.tf
├── variables.tf
├── outputs.tf
├── lambdas/
│   ├── auth_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── payment_sqs_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── telemedicine_sqs_lambda/
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── pharmacy_ecs_lambda/ # Placeholder, actual ECS service handles logic
│   │   ├── main.py
│   │   └── requirements.txt
│   └── pfm_ec2_lambda/    # Placeholder, actual EC2 instance handles logic
│       ├── main.py
│       └── requirements.txt
└── scripts/
    └── package_lambdas.sh
1. main.tf - Main Terraform Configuration

This file defines all AWS resources.

Terraform


2. variables.tf - Input Variables

Terraform



Terraform


4. Lambda Function Code (Place these in the lambdas/ directory)

lambdas/auth_lambda/main.py (FusionAuth Custom Authorizer)
No change from previous response.

Python



boto3


boto3
lambdas/pharmacy_ecs_lambda/main.py (Placeholder for Pharmacy ECS service)
This Lambda is a placeholder. The actual logic for Pharmacy will reside in the ECS service behind the ALB.

Python

# lambdas/pharmacy_ecs_lambda/main.py
import json

def handler(event, context):
    # This Lambda is just a placeholder for the zip archive.
    # The actual Pharmacy microservice logic runs on ECS.
    return {
        "statusCode": 200,
        "body": json.dumps("This is a placeholder Lambda for Pharmacy ECS service.")
    }
lambdas/pharmacy_ecs_lambda/requirements.txt
(Empty)

lambdas/pfm_ec2_lambda/main.py (Placeholder for Personal Health Management EC2 instance)
This Lambda is a placeholder. The actual logic for PFM will reside on the EC2 instance behind the ALB.

Python

# lambdas/pfm_ec2_lambda/main.py
import json

def handler(event, context):
    # This Lambda is just a placeholder for the zip archive.
    # The actual Personal Health Management microservice logic runs on EC2.
    return {
        "statusCode": 200,
        "body": json.dumps("This is a placeholder Lambda for Personal Health Management EC2 instance.")
    }
lambdas/pfm_ec2_lambda/requirements.txt
(Empty)

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

# Payment SQS Lambda
echo "Packaging payment_sqs_lambda..."
cd lambdas/payment_sqs_lambda
pip install -r requirements.txt -t .
zip -r ../payment_sqs_lambda.zip .
rm -rf lib python *.dist-info
cd ../..

# Telemedicine SQS Lambda
echo "Packaging telemedicine_sqs_lambda..."
cd lambdas/telemedicine_sqs_lambda
pip install -r requirements.txt -t .
zip -r ../telemedicine_sqs_lambda.zip .
rm -rf lib python *.dist-info
cd ../..

# Pharmacy ECS Lambda (Placeholder)
echo "Packaging pharmacy_ecs_lambda..."
cd lambdas/pharmacy_ecs_lambda
# No requirements.txt for this example, but if there were:
# pip install -r requirements.txt -t .
zip -r ../pharmacy_ecs_lambda.zip .
cd ../..

# PFM EC2 Lambda (Placeholder)
echo "Packaging pfm_ec2_lambda..."
cd lambdas/pfm_ec2_lambda
# No requirements.txt for this example, but if there were:
# pip install -r requirements.txt -t .
zip -r ../pfm_ec2_lambda.zip .
cd ../..

echo "Lambda packaging complete."
Make this script executable: chmod +x scripts/package_lambdas.sh

Implementation Steps:

Install Terraform: If you haven't already, install Terraform: https://developer.hashicorp.com/terraform/downloads

Set up AWS CLI: Configure your AWS CLI with appropriate credentials and default region. Terraform will use these.

Set up FusionAuth:

Deploy a FusionAuth instance.

Create an application within FusionAuth.

Generate an API Key with permissions to POST /api/jwt/validate.

Note your FusionAuth domain (e.g., https://your-fusionauth.com) and the API Key.

Prepare Lambda Code:

Create the lambdas/ directory and its subdirectories as shown in the structure.

Place the Python code and requirements.txt files into their respective directories.

Run scripts/package_lambdas.sh to create the .zip files for your Lambda functions. You'll need pip installed.

Find a suitable AMI for EC2:

For the aws_instance.pfm_ec2_instance, you need to replace "ami-0abcdef1234567890" with a valid AMI ID for your chosen aws_region.

If you plan to run MSSQL directly on EC2, you'll need a Windows Server AMI with SQL Server pre-installed, or install it yourself via user_data. For a simple test, a basic Linux AMI with Nginx is used as a placeholder.

You can find AMIs in the AWS EC2 console under "Launch Instances" -> "AMIs", or using the AWS CLI: aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query 'sort_by(Images, &CreationDate)[-1].ImageId' for Amazon Linux 2.

Initialize Terraform:

Bash

terraform init
Plan the Deployment:

Bash

terraform plan \
  -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" \
  -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY" \
  -var="db_password=YOUR_DB_PASSWORD" \
  -var="ec2_key_pair_name=YOUR_EC2_KEY_PAIR_NAME" # Optional, if you have one
Replace placeholders with your actual values. For sensitive variables like passwords and API keys, consider using a terraform.tfvars file or environment variables.

Apply the Configuration:

Bash

terraform apply \
  -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" \
  -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY" \
  -var="db_password=YOUR_DB_PASSWORD" \
  -var="ec2_key_pair_name=YOUR_EC2_KEY_PAIR_NAME"
Confirm the apply when prompted. This will take a significant amount of time as it provisions many resources, including RDS databases.

Test the API:

After terraform apply completes, you will get outputs for api_gateway_base_url, api_key_value, and the DNS names/endpoints of your backend services.

Obtain a JWT from your FusionAuth instance.

Example curl commands:

Bash

# Get outputs from Terraform
API_URL=$(terraform output -raw api_gateway_base_url)
API_KEY=$(terraform output -raw api_key_value)
# Assume you have a JWT_TOKEN obtained from FusionAuth
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Replace with your actual JWT

echo "API Gateway Base URL: ${API_URL}/prod"
echo "API Key: ${API_KEY}"

# Test Payment Service (sends to SQS)
echo "--- Testing Payment Service ---"
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"transaction_id": "txn123", "amount": 100.50, "currency": "USD", "description": "Online purchase"}' \
  "${API_URL}/prod/payments/process"

# Test Telemedicine Service (sends to SQS)
echo "--- Testing Telemedicine Service ---"
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"appointment_id": "appt456", "patient_id": "pat789", "doctor_id": "doc101", "appointment_time": "2025-07-20T10:00:00Z"}' \
  "${API_URL}/prod/telemedicine/schedule"

# Test Pharmacy Service (routes to ALB -> ECS)
echo "--- Testing Pharmacy Service ---"
curl -v -X GET \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  "${API_URL}/prod/pharmacy/medications"

# Test Personal Health Management Service (routes to ALB -> EC2)
echo "--- Testing Personal Health Management Service ---"
curl -v -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user001", "metric": "weight", "value": 175.5, "date": "2025-07-16"}' \
  "${API_URL}/prod/personal-health-management/data"

# Test Unauthorized Access (without token)
echo "--- Testing Unauthorized Access ---"
curl -v -X GET "${API_URL}/prod/payments/process"

# Test Rate Limiting (send many requests quickly with the API_KEY)
# You'll start seeing 429 Too Many Requests errors if you exceed the throttle limits
Clean up (optional):

Bash

terraform destroy \
  -var="fusionauth_domain=YOUR_FUSIONAUTH_DOMAIN" \
  -var="fusionauth_api_key=YOUR_FUSIONAUTH_API_KEY" \
  -var="db_password=YOUR_DB_PASSWORD" \
  -var="ec2_key_pair_name=YOUR_EC2_KEY_PAIR_NAME"
Confirm the destroy when prompted. This will also take a long time due to RDS deletion.

Detailed Explanation of New Components and Integrations:

VPC and Networking:

A aws_vpc is created to host all your private resources (Lambdas, ECS, EC2, RDS).

public_a, public_b subnets are for public-facing resources like ALBs and NAT Gateways.

private_a, private_b subnets are for private resources.

aws_internet_gateway provides internet access to the VPC.

aws_nat_gateway in a public subnet allows resources in private subnets to initiate outbound connections (e.g., Lambda fetching dependencies, ECS pulling images).

aws_route_table and aws_route_table_association manage network traffic routing.

Security Groups (aws_security_group): Crucial for controlling traffic flow between components.

lambda_sg: Allows Lambdas to make outbound connections.

alb_sg: Allows inbound HTTP/HTTPS traffic to the ALBs.

ecs_tasks_sg: Allows inbound traffic from the Pharmacy ALB to ECS tasks, and outbound to PostgreSQL.

ec2_instances_sg: Allows inbound traffic from the PFM ALB to EC2, and outbound to MSSQL.

rds_postgres_sg / rds_mssql_sg: Restricts inbound database traffic only to the respective application security groups (ECS for Postgres, EC2 for MSSQL).

Payment & Telemedicine Services (API Gateway -> SQS -> Lambda -> DynamoDB):

SQS Queues (aws_sqs_queue): Act as asynchronous buffers. API Gateway sends messages to SQS, decoupling the API call from the backend processing. This improves responsiveness and resilience.

API Gateway SQS Integration (type = "AWS", uri to SQS, credentials):

The uri is arn:aws:apigateway:<region>:sqs:path/<queue_name>, which is a special format for API Gateway to interact with SQS.

credentials points to aws_iam_role.api_gateway_sqs_role, granting API Gateway permission to send messages to SQS.

request_templates: This is vital. API Gateway receives a JSON request, but SQS's SendMessage action expects a specific x-www-form-urlencoded format. The template transforms the incoming JSON body into the MessageBody parameter for SQS. MessageDeduplicationId and MessageGroupId are included for FIFO queues (though these are standard SQS queues, these parameters are still valid).

Lambda SQS Event Source Mapping (aws_lambda_event_source_mapping): Configures the Lambda function to automatically poll the SQS queue and invoke the Lambda with new messages.

DynamoDB Tables (aws_dynamodb_table): NoSQL databases for high-performance, scalable data storage.

Lambda Code (main.py for SQS Lambdas): These Lambdas are triggered by SQS messages. They parse the message body (which is URL-encoded JSON from API Gateway), and then interact with DynamoDB using boto3.

Pharmacy Service (API Gateway -> ALB -> ECS -> PostgreSQL):

ECS Cluster (aws_ecs_cluster): A logical grouping for your ECS services.

ECS Task Definition (aws_ecs_task_definition): Defines your application container, CPU/memory, network mode (awsvpc for Fargate), and environment variables (e.g., for database connection details). You'll need to replace nginx:latest with your actual microservice Docker image.

ECS Service (aws_ecs_service): Maintains the desired count of tasks, handles deployments, and integrates with the ALB.

Application Load Balancer (aws_lb): Distributes incoming HTTP/HTTPS traffic across multiple targets (ECS tasks in this case). It's internet-facing in this example.

ALB Target Group (aws_lb_target_group): A logical grouping of targets (ECS tasks) that the ALB routes requests to. It also defines health checks.

ALB Listener (aws_lb_listener): Checks for connection requests from clients, using the protocol and port that you configure, and forwards requests to a target group.

RDS PostgreSQL (aws_db_instance): A managed relational database service. It's placed in private subnets and secured by rds_postgres_sg to only allow connections from ECS tasks.

API Gateway ALB Integration (type = "HTTP_PROXY", uri to ALB DNS): API Gateway acts as a direct proxy to the ALB. The {proxy} variable in the URI ensures that the full path from the API Gateway request is passed through to the ALB and then to the ECS service.

Personal Health Management Service (API Gateway -> ALB -> EC2 -> MSSQL):

EC2 Instance (aws_instance): A virtual server where your PFM microservice would run. It's placed in a private subnet and attached to the ec2_instances_sg.

RDS MSSQL (aws_db_instance): Managed SQL Server database. Similar to PostgreSQL, it's in private subnets and secured by rds_mssql_sg to only allow connections from the EC2 instance.

ALB Integration: Works identically to the Pharmacy service, routing traffic from API Gateway to the ALB, which then forwards to the EC2 instance.

user_data for EC2: This script runs when the EC2 instance first launches. You would use it to install your application, web server (like IIS for Windows or Nginx/Apache for Linux), and configure it to connect to the MSSQL database.

Response Processing:

For SQS integrations, the API Gateway immediately returns a 200 OK if the message is successfully sent to SQS. The actual processing and any eventual response to the client (if needed for asynchronous operations) would be handled by a separate mechanism (e.g., WebSockets, polling, or callbacks).

For ALB integrations, API Gateway acts as a proxy. The response from the ECS service or EC2 instance is directly returned to the client.

aws_api_gateway_gateway_response resources are still used for API Gateway-generated errors (e.g., authentication failures, throttling).

Scalability:

All AWS services used (API Gateway, SQS, Lambda, DynamoDB, ALB, ECS) are inherently scalable and managed by AWS, reducing operational overhead.

ECS services can be configured with auto-scaling policies to adjust task count based on demand.

EC2 instances can be part of an Auto Scaling Group, though for simplicity, only a single instance is defined here.

RDS instances can be scaled vertically (larger instance types) or horizontally (read replicas, multi-AZ for high availability).

This comprehensive Terraform setup provides a robust and scalable architecture for your microservices, adhering to all your specified requirements. Remember to replace placeholder values and images with your actual application details.