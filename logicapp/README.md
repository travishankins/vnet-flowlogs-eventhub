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
3. Send the blob content to Event Hub via API Connection