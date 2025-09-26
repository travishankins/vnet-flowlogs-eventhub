#!/bin/bash

# Test script for VNet Flow Logs Azure Function
# This script uploads a test blob and simulates the Event Grid notification to the Function

# ⚠️  CONFIGURATION REQUIRED ⚠️
# Update these variables with your actual Azure resources before running:
# - FUNCTION_URL: Your Function App's HTTP trigger URL
# - STG: Your storage account name
# - CONTAINER: Your blob container name

# Configuration (update these with your actual values)
FUNCTION_URL="YOUR_FUNCTION_APP_URL_HERE"  # e.g., https://func-vnet-flowlogs-abc123.azurewebsites.net/api/flowlogs
STG="YOUR_STORAGE_ACCOUNT_NAME"  # Replace with your actual storage account name
CONTAINER="insights-logs-networkflowlog"
BLOB="manual-tests/test-flowlog-$(date +%Y%m%d%H%M%S).json"

echo "🧪 Testing VNet Flow Logs Function App..."
echo "Function URL: $FUNCTION_URL"
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
      "time": "2025-09-26T10:00:00.000Z",
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
                  "1727342400,10.0.0.4,8.8.8.8,12345,53,U,O,A,B,,,,,"
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

# 4) Create Event Grid payload for Function App
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

# 5) Send the Event Grid notification to Function App
echo "🚀 Sending Event Grid notification to Function App..."
echo "Function URL: $FUNCTION_URL"

response=$(curl -s -w "\n%{http_code}" -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d @event-payload.json)

# Extract response body and status code
response_body=$(echo "$response" | head -n -1)
status_code=$(echo "$response" | tail -n 1)

echo "📊 HTTP Status: $status_code"
echo "📋 Response: $response_body"

if [ "$status_code" = "200" ]; then
    echo "✅ Function executed successfully"
else
    echo "❌ Function execution failed"
    exit 1
fi

# 6) Cleanup
echo "🧹 Cleaning up temporary files..."
rm -f test-flowlog.json event-payload.json

echo ""
echo "🎉 Function test completed!"
echo "💡 Monitor: Azure Portal > Function App > Functions > flowlogs > Monitor"
echo "📊 Check Application Insights for detailed logs and metrics"
echo "🔍 Verify Event Hub received the data in Azure Portal > Event Hubs > nsgflowhub"