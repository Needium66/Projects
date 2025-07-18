#######################################################
#Telemedicine Microservices
#########################################################
lambdas/telemedicine_sqs_lambda/main.py (Telemedicine Microservice Lambda - SQS triggered)

Python

# lambdas/telemedicine_sqs_lambda/main.py
import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'TelemedicineData') # Default for local testing
telemedicine_table = dynamodb.Table(table_name)

def handler(event, context):
    print(f"Telemedicine SQS Lambda received event: {json.dumps(event)}")

    for record in event['Records']:
        message_body = record['body']
        try:
            import urllib.parse
            decoded_body = urllib.parse.unquote_plus(message_body)
            appointment_data = json.loads(decoded_body)

            # Process appointment_data and store in DynamoDB
            item = {
                'id': appointment_data.get('appointment_id', record['messageId']),
                'patient_id': appointment_data.get('patient_id'),
                'doctor_id': appointment_data.get('doctor_id'),
                'appointment_time': appointment_data.get('appointment_time'),
                'status': 'scheduled',
                'timestamp': record['attributes']['SentTimestamp']
            }
            telemedicine_table.put_item(Item=item)
            print(f"Successfully processed telemedicine appointment and stored in DynamoDB: {item}")

        except json.JSONDecodeError as e:
            print(f"Error decoding JSON from SQS message: {e} - Body: {message_body}")
        except Exception as e:
            print(f"Error processing SQS message or writing to DynamoDB: {e}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully')
    }
lambdas/telemedicine_sqs_lambda/requirements.txt