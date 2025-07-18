#################################################################
#Payment Microservices
#################################################################
requests
functions/payment_processor_function/main.py (Payment Microservice Cloud Function - Pub/Sub triggered)

Python

# functions/payment_processor_function/main.py
import base64
import json
import logging
from google.cloud import firestore

# Configure logging
logging.basicConfig(level=logging.INFO)

db = firestore.Client()
FIRESTORE_COLLECTION_NAME = os.environ.get('FIRESTORE_COLLECTION_NAME', 'payments')

def handler(event, context):
    """Triggered by a Pub/Sub message."""
    logging.info(f"Payment processor function triggered by event: {event}")

    if 'data' in event:
        try:
            # Pub/Sub message data is base64 encoded
            message_data = base64.b64decode(event['data']).decode('utf-8')
            payment_request = json.loads(message_data)

            logging.info(f"Processing payment request: {payment_request}")

            # Add a timestamp and status
            payment_request['status'] = 'processed'
            payment_request['timestamp'] = firestore.SERVER_TIMESTAMP

            # Store in Firestore
            doc_ref = db.collection(FIRESTORE_COLLECTION_NAME).add(payment_request)
            logging.info(f"Payment request stored in Firestore with ID: {doc_ref[1].id}")

        except json.JSONDecodeError as e:
            logging.error(f"Failed to decode JSON from Pub/Sub message: {e}")
            raise # Re-raise to indicate failure, Pub/Sub will retry
        except Exception as e:
            logging.error(f"Error processing payment request: {e}")
            raise # Re-raise to indicate failure, Pub/Sub will retry
    else:
        logging.warning("No data found in Pub/Sub message event.")

functions/payment_processor_function/requirements.txt
