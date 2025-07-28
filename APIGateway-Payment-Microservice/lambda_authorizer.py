#######################################################
#FusionAuth Custom Authorizer Lambda Code
#######################################################
# lambda_authorizer.py
import json
import os
import jwt
from jwt.algorithms import RSAAlgorithm
import requests
import base64

# --- Configuration ---
# Replace with your FusionAuth tenant ID
FUSIONAUTH_TENANT_ID = os.environ.get('FUSIONAUTH_TENANT_ID', 'YOUR_FUSIONAUTH_TENANT_ID')
# Replace with your FusionAuth issuer (e.g., https://your-fusionauth-domain.com)
FUSIONAUTH_ISSUER = os.environ.get('FUSIONAUTH_ISSUER', 'https://your-fusionauth-domain.com')
# Replace with your FusionAuth JWKS endpoint (e.g., https://your-fusionauth-domain.com/.well-known/jwks.json)
FUSIONAUTH_JWKS_URL = os.environ.get('FUSIONAUTH_JWKS_URL', 'https://your-fusionauth-domain.com/.well-known/jwks.json')

# Cache for JWKS to avoid fetching on every invocation
_jwks_client = None

def get_jwks_client():
    """Fetches and caches the JWKS client."""
    global _jwks_client
    if _jwks_client is None:
        try:
            response = requests.get(FUSIONAUTH_JWKS_URL, timeout=5)
            response.raise_for_status()
            jwks_data = response.json()
            _jwks_client = jwt.PyJWKClient(FUSIONAUTH_JWKS_URL, jwks_data=jwks_data)
        except requests.exceptions.RequestException as e:
            print(f"Error fetching JWKS: {e}")
            raise Exception("Unauthorized") # Or handle more gracefully
    return _jwks_client

def generate_policy(principal_id, effect, resource):
    """Generates an IAM policy for API Gateway."""
    auth_response = {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
    }
    return auth_response

def lambda_handler(event, context):
    """
    Lambda handler for custom authorizer. Validates JWT from FusionAuth.
    """
    print(f"Authorizer event: {json.dumps(event)}")

    token = None
    # Extract token from Authorization header
    if 'authorizationToken' in event:
        token = event['authorizationToken']
    elif 'headers' in event and 'Authorization' in event['headers']:
        token = event['headers']['Authorization']

    if not token:
        print("Authorization header missing or empty.")
        return generate_policy('user', 'Deny', event['methodArn'])

    # Strip "Bearer " prefix if present
    if token.startswith('Bearer '):
        token = token[len('Bearer '):]

    try:
        jwks_client = get_jwks_client()
        signing_key = jwks_client.get_signing_key_from_jwt(token)

        # Decode and verify the token
        # audience (aud) should be the API Gateway URL or a specific identifier for your API
        # issuer (iss) should match your FusionAuth issuer URL
        # tenantId (tid) is a custom claim often used by FusionAuth
        decoded_token = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"], # Ensure this matches your FusionAuth configuration
            audience="your-api-gateway-audience", # IMPORTANT: Replace with your actual API Gateway audience
            issuer=FUSIONAUTH_ISSUER,
            options={"require": ["exp", "iat", "iss", "aud"]},
        )

        # Optional: Further validation of claims (e.g., roles, permissions)
        # if decoded_token.get('tid') != FUSIONAUTH_TENANT_ID:
        #     print("Tenant ID mismatch.")
        #     return generate_policy('user', 'Deny', event['methodArn'])

        print(f"Token successfully decoded for user: {decoded_token.get('sub')}")
        return generate_policy(decoded_token.get('sub'), 'Allow', event['methodArn'])

    except jwt.exceptions.PyJWTError as e:
        print(f"JWT validation error: {e}")
        return generate_policy('user', 'Deny', event['methodArn'])
    except Exception as e:
        print(f"Unexpected error: {e}")
        return generate_policy('user', 'Deny', event['methodArn'])

