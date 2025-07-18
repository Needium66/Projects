#####################################################################
#Helper Script
####################################################################
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