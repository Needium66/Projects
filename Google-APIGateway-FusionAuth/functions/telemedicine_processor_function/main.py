####################################################################
#Telemedicine Microservices
####################################################################
google-cloud-firestore
functions/telemedicine_processor_function/main.py (Telemedicine Microservice Cloud Function - Pub/Sub triggered)

Python

# functions/telemedicine_processor_function/main.py
import base64
import json
import logging
from google.cloud import firestore

# Configure logging
logging.basicConfig(level=logging.INFO)

db = firestore.Client()
FIRESTORE_COLLECTION_NAME = os.environ.get('FIRESTORE_COLLECTION_NAME', 'telemedicine_appointments')

def handler(event, context):
    """Triggered by a Pub/Sub message."""
    logging.info(f"Telemedicine processor function triggered by event: {event}")

    if 'data' in event:
        try:
            message_data = base64.b64decode(event['data']).decode('utf-8')
            appointment_request = json.loads(message_data)

            logging.info(f"Processing telemedicine appointment request: {appointment_request}")

            appointment_request['status'] = 'scheduled'
            appointment_request['timestamp'] = firestore.SERVER_TIMESTAMP

            doc_ref = db.collection(FIRESTORE_COLLECTION_NAME).add(appointment_request)
            logging.info(f"Telemedicine appointment request stored in Firestore with ID: {doc_ref[1].id}")

        except json.JSONDecodeError as e:
            logging.error(f"Failed to decode JSON from Pub/Sub message: {e}")
            raise
        except Exception as e:
            logging.error(f"Error processing telemedicine request: {e}")
            raise
    else:
        logging.warning("No data found in Pub/Sub message event.")

functions/telemedicine_processor_function/requirements.txt