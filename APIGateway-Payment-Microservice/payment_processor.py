#########################################
#Payment Processor Lambda Code
#########################################
# payment_processor.py
import json
import os
import uuid
import boto3
from datetime import datetime

# --- AWS Clients ---
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# --- Configuration ---
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'payments')
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL', 'YOUR_SQS_QUEUE_URL') # Will be set by Terraform

def lambda_handler(event, context):
    """
    Lambda handler for payment processing.
    Handles POST requests to create payments and GET requests to retrieve payments.
    """
    print(f"Payment Processor event: {json.dumps(event)}")

    http_method = event.get('httpMethod')
    path = event.get('path')

    if http_method == 'POST' and path == '/payments':
        return handle_create_payment(event)
    elif http_method == 'GET' and path.startswith('/payments/'):
        return handle_get_payment(event)
    elif http_method == 'GET' and path == '/payments':
        return handle_list_payments(event)
    else:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Unsupported HTTP method or path'})
        }

def handle_create_payment(event):
    """Handles the creation of a new payment."""
    try:
        body = json.loads(event.get('body', '{}'))
        amount = body.get('amount')
        currency = body.get('currency')
        description = body.get('description')
        user_id = event.get('requestContext', {}).get('authorizer', {}).get('principalId', 'anonymous') # From Authorizer

        if not all([amount, currency]):
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Missing required fields: amount, currency'})
            }

        payment_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat() + 'Z' # ISO 8601 format

        payment_item = {
            'paymentId': payment_id,
            'userId': user_id,
            'amount': amount,
            'currency': currency,
            'description': description,
            'status': 'PENDING', # Initial status
            'createdAt': timestamp,
            'updatedAt': timestamp
        }

        # Store in DynamoDB
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        table.put_item(Item=payment_item)
        print(f"Payment {payment_id} stored in DynamoDB.")

        # Send message to SQS for asynchronous processing
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps({
                'paymentId': payment_id,
                'action': 'process_payment',
                'details': payment_item
            })
        )
        print(f"Message for payment {payment_id} sent to SQS.")

        return {
            'statusCode': 202, # Accepted for processing
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'message': 'Payment request accepted for processing',
                'paymentId': payment_id,
                'status': 'PENDING'
            })
        }

    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Invalid JSON body'})
        }
    except Exception as e:
        print(f"Error creating payment: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Internal server error: {str(e)}'})
        }

def handle_get_payment(event):
    """Retrieves a single payment by ID."""
    try:
        path_parameters = event.get('pathParameters', {})
        payment_id = path_parameters.get('paymentId')
        user_id = event.get('requestContext', {}).get('authorizer', {}).get('principalId', 'anonymous')

        if not payment_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Missing paymentId in path'})
            }

        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        response = table.get_item(Key={'paymentId': payment_id})
        item = response.get('Item')

        if not item:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Payment not found'})
            }

        # Optional: Ensure the user is authorized to view this payment
        if item.get('userId') != user_id and user_id != 'admin': # Example: allow admin or owner
             return {
                'statusCode': 403,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Forbidden: You do not have access to this payment'})
            }

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(item)
        }

    except Exception as e:
        print(f"Error getting payment: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Internal server error: {str(e)}'})
        }

def handle_list_payments(event):
    """Retrieves a list of payments for the authenticated user."""
    try:
        user_id = event.get('requestContext', {}).get('authorizer', {}).get('principalId', 'anonymous')

        if user_id == 'anonymous':
            return {
                'statusCode': 403,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Authentication required to list payments'})
            }

        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        # In a real application, you'd likely use a GSI for userId to query efficiently
        # For simplicity, this example scans and filters, which is not efficient for large tables.
        # A better approach would be to use a Global Secondary Index (GSI) on userId.
        response = table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr('userId').eq(user_id)
        )
        items = response.get('Items', [])

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(items)
        }

    except Exception as e:
        print(f"Error listing payments: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Internal server error: {str(e)}'})
        }
