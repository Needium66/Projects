############################################################
#Payment Microservices
############################################################
# lambdas/payment_sqs_lambda/main.py
import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'PaymentData') # Default for local testing
payment_table = dynamodb.Table(table_name)

def handler(event, context):
    print(f"Payment SQS Lambda received event: {json.dumps(event)}")

    for record in event['Records']:
        message_body = record['body']
        try:
            # The message_body from API Gateway SQS integration is URL-encoded string of the original JSON body
            # So we need to URL-decode it first, then load it as JSON
            import urllib.parse
            decoded_body = urllib.parse.unquote_plus(message_body)
            payment_data = json.loads(decoded_body)

            # Process payment_data and store in DynamoDB
            # In a real application, you'd add more robust processing and error handling
            item = {
                'id': payment_data.get('transaction_id', record['messageId']), # Use a provided ID or SQS message ID
                'amount': payment_data.get('amount'),
                'currency': payment_data.get('currency'),
                'status': 'processed',
                'timestamp': record['attributes']['SentTimestamp']
            }
            payment_table.put_item(Item=item)
            print(f"Successfully processed payment and stored in DynamoDB: {item}")

        except json.JSONDecodeError as e:
            print(f"Error decoding JSON from SQS message: {e} - Body: {message_body}")
            # Depending on your DLQ strategy, you might re-raise or log this
        except Exception as e:
            print(f"Error processing SQS message or writing to DynamoDB: {e}")
            # Re-raise the exception to trigger SQS redelivery/DLQ
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully')
    }
lambdas/payment_sqs_lambda/requirements.txt