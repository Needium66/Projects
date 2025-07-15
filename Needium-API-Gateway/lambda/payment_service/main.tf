#####################################################
#Main file for Payment
#####################################################
import json

def handler(event, context):
    """
    Lambda handler for the Payment Service.
    Processes payment requests.
    """
    print(f"Payment Service received event: {json.dumps(event)}")

    # Extract user information from the authorizer context (Cognito JWT claims)
    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub', 'anonymous')
    username = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username', 'anonymous')

    try:
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            amount = body.get('amount')
            currency = body.get('currency', 'USD')
            description = body.get('description', 'No description')

            # Simulate payment processing
            if amount is None or not isinstance(amount, (int, float)):
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Invalid amount provided.'})
                }

            transaction_id = f"PAY-{abs(hash(f'{user_id}-{amount}-{currency}-{description}'))}" # Simple mock ID
            print(f"User {username} ({user_id}) processed payment of {amount} {currency} for '{description}'")

            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Payment processed successfully!',
                    'transactionId': transaction_id,
                    'amount': amount,
                    'currency': currency,
                    'user': username
                })
            }
        elif event['httpMethod'] == 'GET':
            # Simulate fetching payment history for the user
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': f'Payment history for user {username} ({user_id}) retrieved.',
                    'history': [
                        {'id': 'PAY-001', 'amount': 25.50, 'currency': 'USD', 'date': '2025-07-01'},
                        {'id': 'PAY-002', 'amount': 120.00, 'currency': 'USD', 'date': '2025-07-05'}
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
        print(f"Error in Payment Service: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }