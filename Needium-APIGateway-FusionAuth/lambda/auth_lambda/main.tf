###############################################################
#main.tf file for lambda code of fusion auth custom authorizer
###############################################################
# lambdas/auth_lambda/main.py
import json
import os
import requests

FUSIONAUTH_DOMAIN = os.environ.get("FUSIONAUTH_DOMAIN")
FUSIONAUTH_API_KEY = os.environ.get("FUSIONAUTH_API_KEY")

def generate_policy(principal_id, effect, resource):
    auth_response = {}
    auth_response['principalId'] = principal_id

    if effect and resource:
        policy_document = {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
        auth_response['policyDocument'] = policy_document
    return auth_response

def handler(event, context):
    try:
        token = event['authorizationToken']
        if not token or not token.startswith("Bearer "):
            print("Invalid or missing Bearer token")
            raise Exception("Unauthorized")

        jwt = token.split(" ")[1]

        # Call FusionAuth to validate the JWT
        headers = {
            "Authorization": FUSIONAUTH_API_KEY,
            "Content-Type": "application/json"
        }
        validate_url = f"{FUSIONAUTH_DOMAIN}/api/jwt/validate"
        body = json.dumps({"jwt": jwt})

        response = requests.post(validate_url, headers=headers, data=body)
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)

        validation_result = response.json()

        if validation_result.get('isValid'):
            # Assuming the JWT payload contains user information in 'jwt.sub' (subject)
            # You might want to extract more user info from the decoded JWT payload
            # for context in your backend services.
            # FusionAuth often puts user ID in 'sub' and roles/permissions in custom claims.
            principal_id = validation_result.get('jwt', {}).get('sub', 'unknown')
            print(f"Token is valid for principal: {principal_id}")
            return generate_policy(principal_id, 'Allow', event['methodArn'])
        else:
            print(f"Token validation failed: {validation_result.get('error')}")
            raise Exception("Unauthorized")

    except requests.exceptions.RequestException as e:
        print(f"Error calling FusionAuth: {e}")
        raise Exception("Unauthorized")
    except Exception as e:
        print(f"Authentication error: {e}")
        raise Exception("Unauthorized")