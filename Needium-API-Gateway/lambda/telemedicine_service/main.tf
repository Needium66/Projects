###########################################################
#Main file for telemedicine service
###########################################################
import json

def handler(event, context):
    """
    Lambda handler for the Telemedicine Service.
    Manages virtual appointments and consultations.
    """
    print(f"Telemedicine Service received event: {json.dumps(event)}")

    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub', 'anonymous')
    username = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username', 'anonymous')

    try:
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            appointment_time = body.get('appointmentTime')
            doctor_specialty = body.get('doctorSpecialty')

            if not appointment_time or not doctor_specialty:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Missing appointmentTime or doctorSpecialty'})
                }

            # Simulate booking an appointment
            appointment_id = f"TEL-{abs(hash(f'{user_id}-{appointment_time}-{doctor_specialty}'))}"
            print(f"User {username} ({user_id}) booked telemedicine appointment for {appointment_time} with {doctor_specialty}")

            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Telemedicine appointment booked successfully!',
                    'appointmentId': appointment_id,
                    'time': appointment_time,
                    'specialty': doctor_specialty,
                    'user': username
                })
            }
        elif event['httpMethod'] == 'GET':
            # Simulate fetching upcoming appointments
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': f'Upcoming telemedicine appointments for user {username} ({user_id}) retrieved.',
                    'appointments': [
                        {'id': 'TEL-001', 'time': '2025-07-20 10:00 AM', 'specialty': 'Dermatology'},
                        {'id': 'TEL-002', 'time': '2025-07-25 02:00 PM', 'specialty': 'Pediatrics'}
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
        print(f"Error in Telemedicine Service: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }