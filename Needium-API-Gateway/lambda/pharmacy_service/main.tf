#####################################################
#Main file for Pharmacy Service
#####################################################
import json

def handler(event, context):
    """
    Lambda handler for the Pharmacy Service.
    Manages prescription refills and pharmacy orders.
    """
    print(f"Pharmacy Service received event: {json.dumps(event)}")

    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub', 'anonymous')
    username = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username', 'anonymous')

    try:
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            prescription_id = body.get('prescriptionId')
            delivery_address = body.get('deliveryAddress')

            if not prescription_id or not delivery_address:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Missing prescriptionId or deliveryAddress'})
                }

            # Simulate ordering a prescription refill
            order_id = f"PHARM-{abs(hash(f'{user_id}-{prescription_id}'))}"
            print(f"User {username} ({user_id}) ordered refill for {prescription_id} to {delivery_address}")

            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Prescription refill ordered successfully!',
                    'orderId': order_id,
                    'prescriptionId': prescription_id,
                    'deliveryAddress': delivery_address,
                    'user': username
                })
            }
        elif event['httpMethod'] == 'GET':
            # Simulate fetching order history
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': f'Pharmacy order history for user {username} ({user_id}) retrieved.',
                    'orders': [
                        {'id': 'PHARM-001', 'prescription': 'RX-123', 'status': 'Delivered', 'date': '2025-06-15'},
                        {'id': 'PHARM-002', 'prescription': 'RX-456', 'status': 'Processing', 'date': '2025-07-10'}
                    ]
                })
            }
        else:
            return {
                'statusCode': 405,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Method Not Allowed'})
            }
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Invalid JSON in request body'})
        }
    except Exception as e:
        print(f"Error in Pharmacy Service: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }