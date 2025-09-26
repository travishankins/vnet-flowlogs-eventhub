# Azure Function App Version

This folder contains the Azure Function App implementation of the VNet Flow Logs processor, offering an alternative to the Logic App approach.

## Function App Advantages

### Performance & Control
- **Faster execution** - Direct Python code vs Logic App workflow orchestration
- **Better error handling** - Custom exception handling and retry logic
- **More flexible processing** - Can perform complex data transformations
- **Lower latency** - Minimal overhead compared to Logic App steps

### Cost Efficiency
- **Consumption billing** - Pay only for actual execution time
- **Better resource utilization** - More efficient for high-volume scenarios
- **No connector costs** - Direct API calls vs Logic App connector pricing

### Monitoring & Debugging
- **Application Insights integration** - Rich telemetry and performance metrics
- **Custom logging** - Detailed application logs for troubleshooting
- **Live debugging** - Can attach debugger for development

## Architecture

```
Event Grid → Function App (HTTP Trigger) → Storage (Managed Identity) → Event Hub
```

1. **Event Grid** sends blob creation notifications to Function HTTP endpoint
2. **Function App** processes the event using Python code
3. **Managed Identity** authentication for secure access to Storage and Event Hub
4. **Event Hub** receives the processed flow log data

## Files Structure

```
function-app/
├── __init__.py          # Main function code
├── function.json        # Function binding configuration
├── requirements.txt     # Python dependencies
└── host.json           # Function app configuration
```

## Deployment Process

### 1. Deploy Function App Infrastructure
```bash
# Configure your values in the script first
./scripts/deploy-function-app.sh
```

### 2. Configure RBAC Permissions
```bash
# Update script with your resource names
./scripts/configure-function-rbac.sh
```

### 3. Test the Function
```bash
# Update script with your Function URL
./scripts/test-function.sh
```

## Configuration Requirements

### Environment Variables
Set these in your Function App:
- `EVENT_HUB_NAMESPACE` - Your Event Hub namespace name
- `EVENT_HUB_NAME` - Event Hub name (default: nsgflowhub)

### Required Permissions (via Managed Identity)
- **Storage Blob Data Reader** - Read flow log blobs
- **Azure Event Hubs Data Sender** - Send processed data to Event Hub

## Function Logic

The function performs these steps:

1. **Validate Event** - Ensures it's a Microsoft.Storage.BlobCreated event
2. **Extract Blob URL** - Gets the blob URL from Event Grid data
3. **Download Blob** - Uses Managed Identity to securely download content
4. **Send to Event Hub** - Forwards the flow log data using Event Hub SDK
5. **Return Response** - Provides success/failure status to Event Grid

## Monitoring

### Application Insights
- Function execution metrics
- Performance monitoring  
- Custom telemetry and logs
- Failure analysis and alerts

### Azure Monitor
- Resource health and availability
- Scaling metrics and recommendations
- Cost analysis and optimization

## Error Handling

The function includes comprehensive error handling:
- **Event validation** - Rejects invalid Event Grid payloads
- **Blob download retry** - Handles transient storage issues
- **Event Hub retry** - Manages temporary Event Hub unavailability
- **Detailed logging** - All errors logged to Application Insights

## Scaling

Function Apps automatically scale based on:
- **Event volume** - More instances for higher Event Grid traffic
- **Processing time** - Additional instances for complex processing
- **Resource utilization** - Scales up/down based on CPU and memory

## Comparison: Function App vs Logic App

| Feature | Function App | Logic App |
|---------|-------------|-----------|
| **Performance** | Faster execution | Visual workflow |
| **Cost** | Usage-based | Connector + execution |
| **Flexibility** | Full code control | Pre-built connectors |
| **Monitoring** | Application Insights | Logic App runs |
| **Debugging** | Code-level debugging | Workflow step debugging |
| **Scaling** | Automatic | Automatic |
| **Complexity** | Code development | Visual designer |

Choose Function App for:
- High-volume scenarios
- Complex processing requirements
- Custom error handling needs
- Lower operational costs

Choose Logic App for:
- Visual workflow design
- Quick prototyping
- Integration with many services
- Minimal code development