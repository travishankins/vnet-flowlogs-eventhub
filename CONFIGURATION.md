# Configuration Guide

Before running the scripts, you need to update the following variables with your specific Azure environment details:

## setup-infrastructure.sh
- `SUBSCRIPTION_ID`: Your Azure subscription ID
- `LOCATION`: Your preferred Azure region (default: westcentralus)
- `RG`: Your resource group name (default: rg-vnet-flow-logs)
- Other variables can remain as defaults (they use random generation for uniqueness)

## configure-managed-identity.sh
- `STORAGE_ACCOUNT`: The storage account name from setup-infrastructure.sh output
- `LOGIC_APP_NAME`: The Logic App name from setup-infrastructure.sh output
- Other variables should match your setup-infrastructure.sh values

## test-upload.sh
- `CALLBACK_URL`: Your Logic App's HTTP trigger callback URL (get from Azure Portal)
- `STG`: Your storage account name (same as in configure-managed-identity.sh)

## How to get your values:
1. **Subscription ID**: `az account show --query id --output tsv`
2. **Logic App Callback URL**: Azure Portal → Logic App → Logic app designer → HTTP trigger → copy URL
3. **Resource names**: Check the output from setup-infrastructure.sh script

## Manual Logic App Configuration Required

After deploying the infrastructure and importing the workflow definition, you must manually configure these connections in the Azure Portal:

### 1. Event Hub Connection Setup
1. Open your Logic App in the Azure Portal
2. Go to Logic app designer
3. Open the "Send_event" action
4. Click "Change connection" or "Add new connection"
5. Choose **"Connect with managed identity"**
6. Configure connection:
   - **Connection Name**: `eventhubs`
   - **Authentication Type**: Managed Identity
   - **Managed Identity**: System-assigned
   - **Event Hub Namespace**: Select your Event Hub namespace (created by setup script)
7. Save the connection

### 2. Verify HTTP Trigger
1. Ensure the HTTP trigger is properly configured
2. Copy the callback URL for use in test-upload.sh
3. The URL format should be: `https://[logic-app].azurewebsites.net:443/api/[workflow]/triggers/When_an_HTTP_request_is_received/invoke?...`

### 3. Test the Workflow
1. Use the configured test-upload.sh script to validate end-to-end functionality
2. Monitor the Logic App run history for successful execution
3. Verify events appear in your Event Hub

## Security Notes:
- Never commit actual subscription IDs, callback URLs, or resource names to public repositories
- Use environment variables or Azure Key Vault for production deployments
- The callback URL contains sensitive signature information - treat it as a secret