########################################################
#Main file for User Management
########################################################
import json

def handler(event, context):
    """
    Lambda handler for User Management (beyond Cognito authentication).
    Handles prompt management, user profile updates, etc.
    """
    print(f"User Management Service received event: {json.dumps(event)}")

    # Extract user information from the authorizer context (Cognito JWT claims)
    # This Lambda would be invoked *after* Cognito has authenticated the user.
    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub', 'anonymous')
    username = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username', 'anonymous')
    email = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('email', 'N/A')

    try:
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            action = body.get('action') # e.g., 'update_profile', 'save_prompt'
            data = body.get('data', {})

            if action == 'update_profile':
                # Simulate updating user profile
                new_name = data.get('name', username)
                print(f"User {username} ({user_id}) updated profile: name={new_name}")
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': 'Profile updated successfully!',
                        'user': {'id': user_id, 'username': new_name, 'email': email}
                    })
                }
            elif action == 'save_prompt':
                prompt_text = data.get('prompt')
                if not prompt_text:
                    return {
                        'statusCode': 400,
                        'headers': {'Content-Type': 'application/json'},
                        'body': json.dumps({'message': 'Prompt text is required.'})
                    }
                # Simulate saving a user's prompt for future reference/analysis
                prompt_id = f"PROMPT-{abs(hash(f'{user_id}-{prompt_text}'))}"
                print(f"User {username} ({user_id}) saved prompt: '{prompt_text}'")
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': 'Prompt saved successfully!',
                        'promptId': prompt_id,
                        'prompt': prompt_text,
                        'user': username
                    })
                }
            else:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Invalid action specified.'})
                }

        elif event['httpMethod'] == 'GET':
            # Simulate fetching user profile or saved prompts
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': f'User profile and recent prompts for {username} ({user_id}) retrieved.',
                    'profile': {'id': user_id, 'username': username, 'email': email},
                    'recent_prompts': [
                        {'id': 'P-001', 'text': 'How do I book a telemedicine appointment?', 'date': '2025-07-12'},
                        {'id': 'P-002', 'text': 'What is my current health summary?', 'date': '2025-07-11'}
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
        print(f"Error in User Management Service: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }