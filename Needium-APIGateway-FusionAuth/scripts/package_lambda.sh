#######################################################
#Helper Scripts for lambda
######################################################
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