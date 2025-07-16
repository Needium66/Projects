##################################################
#Lambda Code for Payment
#################################################
# lambdas/payment_lambda/main.py
import json

def handler(event, context):
    print(f"Payment Microservice received event: {json.dumps(event)}")
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    body = event.get('body', '{}')

    response_body = {
        "message": f"Hello from Payment Service!",
        "received_path": path,
        "http_method": method,
        "body_received": json.loads(body) if body else {},
        "action": "Payment processed successfully (mock response)."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }