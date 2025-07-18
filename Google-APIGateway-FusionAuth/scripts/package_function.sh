#########################################################
#Helper Script
#########################################################
6. scripts/package_functions.sh (Helper Script for Cloud Function Zips)

Bash

#!/bin/bash
set -e

# This script creates zip files for Cloud Functions with their dependencies.

# Auth Function
echo "Packaging auth_function..."
cd functions/auth_function
pip install -r requirements.txt -t .
zip -r ../auth_function.zip .
rm -rf lib python *.dist-info # Clean up downloaded packages
cd ../..

# Payment Processor Function
echo "Packaging payment_processor_function..."
cd functions/payment_processor_function
pip install -r requirements.txt -t .
zip -r ../payment_processor_function.zip .
rm -rf lib python *.dist-info
cd ../..

# Telemedicine Processor Function
echo "Packaging telemedicine_processor_function..."
cd functions/telemedicine_processor_function
pip install -r requirements.txt -t .
zip -r ../telemedicine_processor_function.zip .
rm -rf lib python *.dist-info
cd ../..

echo "Cloud Function packaging complete."
Make this script executable: chmod +x scripts/package_functions.sh