##########################################################
#Cloud Function Code (Placed in the function directory)
#FusionAuth Custom Authorizer
###########################################################

Python

# functions/auth_function/main.py
import json
import os
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

FUSIONAUTH_DOMAIN = os.environ.get("FUSIONAUTH_DOMAIN")
FUSIONAUTH_API_KEY = os.environ.get("FUSIONAUTH_API_KEY")

def handler(request):
    """
    Cloud Function acting as an API Gateway Extensible Authentication (ExtAuth) service.
    It validates a JWT against FusionAuth.
    """
    logging.info(f"Received request for auth_function: {request}")

    # API Gateway sends the Authorization header in the 'Authorization' field of the request headers.
    auth_header = request.headers.get('Authorization')

    if not auth_header or not auth_header.startswith("Bearer "):
        logging.warning("Invalid or missing Bearer token in Authorization header.")
        return json.dumps({"status": "UNAUTHENTICATED", "message": "Missing or invalid Authorization header"}), 401, {'Content-Type': 'application/json'}

    jwt = auth_header.split(" ")[1]

    try:
        # Call FusionAuth to validate the JWT
        headers = {
            "Authorization": FUSIONAUTH_API_KEY,
            "Content-Type": "application/json"
        }
        validate_url = f"{FUSIONAUTH_DOMAIN}/api/jwt/validate"
        body = json.dumps({"jwt": jwt})

        logging.info(f"Calling FusionAuth for JWT validation: {validate_url}")
        response = requests.post(validate_url, headers=headers, data=body)
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)

        validation_result = response.json()
        logging.info(f"FusionAuth validation result: {validation_result}")

        if validation_result.get('isValid'):
            # If valid, return 200 OK to API Gateway.
            # API Gateway will then allow the request to proceed.
            # You can also pass claims back to API Gateway if needed for backend services.
            # For simplicity, we just return a success status.
            return json.dumps({"status": "OK"}), 200, {'Content-Type': 'application/json'}
        else:
            logging.warning(f"JWT validation failed by FusionAuth: {validation_result.get('error', 'No specific error provided')}")
            return json.dumps({"status": "UNAUTHENTICATED", "message": "Invalid token"}), 401, {'Content-Type': 'application/json'}

    except requests.exceptions.RequestException as e:
        logging.error(f"Error calling FusionAuth API: {e}")
        return json.dumps({"status": "UNAUTHENTICATED", "message": "Authentication service unavailable"}), 500, {'Content-Type': 'application/json'}
    except Exception as e:
        logging.error(f"Unexpected error in auth_function: {e}")
        return json.dumps({"status": "UNAUTHENTICATED", "message": "Internal server error"}), 500, {'Content-Type': 'application/json'}

functions/auth_function/requirements.txt