# Logic App Workflows

This folder contains Logic App workflow definitions for processing VNet Flow Logs.

## Workflow Files

### workflow-consumpation.json
- **Use for**: Consumption Logic Apps
- **Deployment**: Standard consumption-based billing model
- **Features**: Pay-per-execution, serverless scaling
- **Configuration**: No `"kind"` property needed

### workflow-standard.json  
- **Use for**: Standard Logic Apps (Premium/App Service Plan)
- **Deployment**: Always-on, dedicated hosting
- **Features**: Stateful workflows, better performance, VNet integration
- **Configuration**: Includes `"kind": "Stateful"` property

## Key Differences

The main differences between the workflow files:

1. **Kind Property**: Standard workflows include `"kind": "Stateful"` at the root level
2. **Billing Model**: Consumption is pay-per-execution, Standard is flat-rate hosting
3. **Performance**: Standard offers better performance and always-on capabilities
4. **Features**: Standard supports more advanced scenarios like VNet integration

## Usage

Choose the appropriate workflow file based on your Logic App type when deploying:

```bash
# For Consumption Logic Apps
az logic workflow create --definition @workflow-consumpation.json ...

# For Standard Logic Apps  
az logic workflow create --definition @workflow-standard.json ...
```

Both workflows implement the same logic:
1. Receive Event Grid notification for blob creation
2. Download the blob using Managed Identity authentication
3. Send the blob content to Event Hub via HTTP REST API using Managed Identity

## Configuration Required

Before deploying, you must update the Event Hub namespace URL in the workflow:

**Line to update:** `"uri": "https://YOUR_EVENTHUB_NAMESPACE.servicebus.windows.net/nsgflowhub/messages"`

Replace `YOUR_EVENTHUB_NAMESPACE` with your actual Event Hub namespace name.

## Required Permissions

The Logic App's Managed Identity requires these role assignments:

1. **Storage Blob Data Reader** - On the storage account containing flow logs
2. **Azure Event Hubs Data Sender** - On the Event Hub namespace

## Why HTTP Action Instead of API Connection?

The workflow uses the HTTP action with Managed Identity to send data directly to Event Hub's REST API instead of using the API Connection connector. This approach:

- Sends **raw JSON data** without wrapper objects or extra encoding
- Ensures SIEM compatibility by delivering data in standard format
- Uses Managed Identity for secure, keyless authentication
- Eliminates the `ContentData` wrapper that many SIEMs cannot parse