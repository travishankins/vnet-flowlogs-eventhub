import azure.functions as func
import azure.durable_functions as df
import logging
import json
import os
from azure.storage.blob import BlobServiceClient
from azure.eventhub import EventHubProducerClient, EventData
from azure.identity import DefaultAzureCredential

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function to process VNet Flow Logs from Event Grid notifications
    and forward them to Event Hub using Managed Identity authentication.
    """
    logging.info('VNet Flow Logs Function triggered via HTTP request.')
    
    try:
        # Parse the Event Grid request
        events = req.get_json()
        if not events or not isinstance(events, list):
            logging.error("Invalid Event Grid payload - expected array of events")
            return func.HttpResponse(
                "Invalid Event Grid payload",
                status_code=400
            )
        
        # Process each event
        processed_count = 0
        for event in events:
            if process_flow_log_event(event):
                processed_count += 1
        
        logging.info(f"Successfully processed {processed_count} out of {len(events)} events")
        
        return func.HttpResponse(
            f"Processed {processed_count} flow log events successfully",
            status_code=200
        )
        
    except Exception as e:
        logging.error(f"Error processing flow log events: {str(e)}")
        return func.HttpResponse(
            f"Error processing events: {str(e)}",
            status_code=500
        )

def process_flow_log_event(event: dict) -> bool:
    """
    Process a single Event Grid event for blob creation.
    Returns True if successfully processed, False otherwise.
    """
    try:
        # Check if this is a blob created event
        if event.get('eventType') != 'Microsoft.Storage.BlobCreated':
            logging.info(f"Skipping event type: {event.get('eventType')}")
            return False
        
        # Extract blob URL from the event
        blob_url = event.get('data', {}).get('url')
        if not blob_url:
            logging.error("No blob URL found in event data")
            return False
        
        logging.info(f"Processing blob: {blob_url}")
        
        # Download blob content using Managed Identity
        blob_content = download_blob_with_managed_identity(blob_url)
        if not blob_content:
            return False
        
        # Send to Event Hub
        return send_to_event_hub(blob_content)
        
    except Exception as e:
        logging.error(f"Error processing individual event: {str(e)}")
        return False

def download_blob_with_managed_identity(blob_url: str) -> str:
    """
    Download blob content using Managed Identity authentication.
    """
    try:
        # Create credential using Managed Identity
        credential = DefaultAzureCredential()
        
        # Parse storage account from URL
        # URL format: https://storageaccount.blob.core.windows.net/container/blob
        parts = blob_url.replace('https://', '').split('/')
        storage_account = parts[0].split('.')[0]
        container_name = parts[1]
        blob_name = '/'.join(parts[2:])
        
        # Create blob service client with Managed Identity
        account_url = f"https://{storage_account}.blob.core.windows.net"
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)
        
        # Download blob content
        blob_client = blob_service_client.get_blob_client(
            container=container_name, 
            blob=blob_name
        )
        
        blob_content = blob_client.download_blob().readall()
        logging.info(f"Successfully downloaded blob: {blob_name} ({len(blob_content)} bytes)")
        
        return blob_content.decode('utf-8')
        
    except Exception as e:
        logging.error(f"Error downloading blob {blob_url}: {str(e)}")
        return None

def send_to_event_hub(content: str) -> bool:
    """
    Send flow log content to Event Hub using Managed Identity.
    """
    try:
        # Get Event Hub configuration from environment variables
        event_hub_namespace = os.environ.get('EVENT_HUB_NAMESPACE')
        event_hub_name = os.environ.get('EVENT_HUB_NAME', 'nsgflowhub')
        
        if not event_hub_namespace:
            logging.error("EVENT_HUB_NAMESPACE environment variable not set")
            return False
        
        # Create Event Hub client with Managed Identity
        credential = DefaultAzureCredential()
        producer_client = EventHubProducerClient(
            fully_qualified_namespace=f"{event_hub_namespace}.servicebus.windows.net",
            eventhub_name=event_hub_name,
            credential=credential
        )
        
        # Create event data
        event_data = EventData(content)
        
        # Send to Event Hub
        with producer_client:
            producer_client.send_batch([event_data])
        
        logging.info(f"Successfully sent flow log data to Event Hub: {event_hub_name}")
        return True
        
    except Exception as e:
        logging.error(f"Error sending to Event Hub: {str(e)}")
        return False