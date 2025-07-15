#####################################################
#Main file for PHM
#####################################################
import json

def handler(event, context):
    """
    Lambda handler for the Personal Health Management Service.
    Manages health records, wellness data, etc.
    """
    print(f"Personal Health Service received event: {json.dumps(event)}")

    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub', 'anonymous')
    username = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username', 'anonymous')

    try:
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            record_type = body.get('recordType')
            data = body.get('data')

            if not record_type or not data:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Missing recordType or data'})
                }

            # Simulate adding a new health record
            record_id = f"HEALTH-{abs(hash(f'{user_id}-{record_type}-{json.dumps(data)}'))}"
            print(f"User {username} ({user_id}) added health record of type {record_type}")

            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Health record added successfully!',
                    'recordId': record_id,
                    'recordType': record_type,
                    'data': data,
                    'user': username
                })
            }
        elif event['httpMethod'] == 'GET':
            # Simulate fetching health data
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': f'Personal health data for user {username} ({user_id}) retrieved.',
                    'records': [
                        {'id': 'HEALTH-001', 'type': 'BloodPressure', 'data': {'systolic': 120, 'diastolic': 80}, 'date': '2025-07-01'},
                        {'id': 'HEALTH-002', 'type': 'Activity', 'data': {'steps': 10245, 'caloriesBurned': 500}, 'date': '2025-07-02'}
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
        print(f"Error in Personal Health Service: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }