#!/bin/bash

# Test script for VNet Flow Logs Logic App
# This script uploads a test blob and simulates the Event Grid notification

# ⚠️  CONFIGURATION REQUIRED ⚠️
# Update these variables with your actual Azure resources before running:
# - CALLBACK_URL: Your Logic App's HTTP trigger URL (get from Azure Portal)
# - STG: Your storage account name
# - CONTAINER: Your blob container name (usually insights-logs-flowlogflowevent)

# Configuration (update these with your actual values)
CALLBACK_URL="YOUR_LOGIC_APP_CALLBACK_URL_HERE"  # Get this from Azure Portal -> Logic App -> HTTP trigger
STG="YOUR_STORAGE_ACCOUNT_NAME"  # Replace with your actual storage account name
CONTAINER="insights-logs-networkflowlog"
BLOB="manual-tests/test-flowlog-$(date +%Y%m%d%H%M%S).json"

echo "🧪 Testing VNet Flow Logs Logic App..."
echo "Storage Account: $STG"
echo "Container: $CONTAINER"
echo "Blob: $BLOB"
echo ""

# 1) Create a realistic VNet flow log test file
echo "📝 Creating test flow log file..."
cat > test-flowlog.json << 'EOF'
{
  "records": [
    {
      "time": "2025-09-23T10:00:00.000Z",
      "systemId": "00000000-0000-0000-0000-000000000000",
      "macAddress": "000000000000",
      "category": "NetworkSecurityGroupFlowEvent",
      "resourceId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/networkSecurityGroups/example-nsg",
      "operationName": "NetworkSecurityGroupFlowEvents",
      "properties": {
        "Version": 2,
        "flows": [
          {
            "rule": "DefaultRule_AllowInternetOutBound",
            "flows": [
              {
                "mac": "000000000000",
                "flowTuples": [
                  "1695456000,10.0.0.4,8.8.8.8,12345,53,U,O,A,B,,,,,"
                ]
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF

# 2) Upload the test file to storage
echo "📤 Uploading test file to storage..."
az storage blob upload \
  --account-name "$STG" \
  --container-name "$CONTAINER" \
  --name "$BLOB" \
  --file test-flowlog.json \
  --auth-mode key \
  --overwrite

if [ $? -eq 0 ]; then
    echo "✅ File uploaded successfully"
else
    echo "❌ File upload failed"
    exit 1
fi

# 3) Construct the blob URL
BLOB_URL="https://${STG}.blob.core.windows.net/${CONTAINER}/${BLOB}"
echo "📍 Blob URL: $BLOB_URL"

# 4) Create Event Grid payload that mimics what Azure sends
echo "🔔 Creating Event Grid notification payload..."
cat > event-payload.json << EOF
[
  {
    "id": "$(uuidgen)",
    "eventType": "Microsoft.Storage.BlobCreated",
    "subject": "/blobServices/default/containers/${CONTAINER}/blobs/${BLOB}",
    "eventTime": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "data": {
      "api": "PutBlob",
      "clientRequestId": "$(uuidgen)",
      "requestId": "$(uuidgen)",
      "eTag": "0x8D1234567890ABC",
      "contentType": "application/json",
      "contentLength": $(wc -c < test-flowlog.json),
      "blobType": "BlockBlob",
      "url": "${BLOB_URL}",
      "sequencer": "000000000000000000000000000000000000000000000000000001"
    },
    "dataVersion": "1.0",
    "metadataVersion": "1"
  }
]
EOF

# 5) Send the Event Grid notification to Logic App
echo "🚀 Sending Event Grid notification to Logic App..."
echo "Logic App URL: $CALLBACK_URL"

curl -X POST "$CALLBACK_URL" \
  -H "Content-Type: application/json" \
  -d @event-payload.json \
  -w "\n📊 HTTP Status: %{http_code}\n" \
  -s

if [ $? -eq 0 ]; then
    echo "✅ Event Grid notification sent successfully"
else
    echo "❌ Failed to send Event Grid notification"
    exit 1
fi

# 6) Cleanup
echo "🧹 Cleaning up temporary files..."
rm -f test-flowlog.json event-payload.json

echo ""
echo "🎉 Test completed! Check your Logic App run history and Event Hub for the processed data."
echo "💡 Monitor: Azure Portal > Logic Apps > Your Logic App > Run History"