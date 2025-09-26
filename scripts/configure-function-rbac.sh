#!/bin/bash

# Configure RBAC permissions for VNet Flow Logs Function App
# This script assigns necessary permissions to the Function App's managed identity

set -e

# Configuration (update these with your actual values from deploy-function-app.sh output)
SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
RG="rg-vnet-flow-logs"
FUNCTION_APP="YOUR_FUNCTION_APP_NAME"
STORAGE_ACCOUNT="YOUR_STORAGE_ACCOUNT_NAME"  # From setup-infrastructure.sh
EVENT_HUB_NAMESPACE="YOUR_EVENT_HUB_NAMESPACE"  # From setup-infrastructure.sh

echo "🔐 Configuring RBAC permissions for Function App managed identity..."
echo "Function App: $FUNCTION_APP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Event Hub Namespace: $EVENT_HUB_NAMESPACE"
echo ""

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Get Function App managed identity principal ID
FUNCTION_PRINCIPAL_ID=$(az functionapp show \
    --resource-group "$RG" \
    --name "$FUNCTION_APP" \
    --query "identity.principalId" \
    --output tsv)

if [ -z "$FUNCTION_PRINCIPAL_ID" ]; then
    echo "❌ Error: Could not retrieve Function App managed identity"
    echo "Make sure the Function App was created with --assign-identity [system]"
    exit 1
fi

echo "Function App Principal ID: $FUNCTION_PRINCIPAL_ID"

# Get resource IDs
STORAGE_RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
EVENT_HUB_RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.EventHub/namespaces/$EVENT_HUB_NAMESPACE"

echo ""
echo "📊 Assigning Storage Blob Data Reader role..."
az role assignment create \
    --role "Storage Blob Data Reader" \
    --assignee "$FUNCTION_PRINCIPAL_ID" \
    --scope "$STORAGE_RESOURCE_ID"

echo "✅ Storage Blob Data Reader role assigned"

echo ""
echo "📤 Assigning Azure Event Hubs Data Sender role..."
az role assignment create \
    --role "Azure Event Hubs Data Sender" \
    --assignee "$FUNCTION_PRINCIPAL_ID" \
    --scope "$EVENT_HUB_RESOURCE_ID"

echo "✅ Azure Event Hubs Data Sender role assigned"

echo ""
echo "✅ RBAC configuration completed!"
echo ""
echo "🔍 Role assignments summary:"
az role assignment list \
    --assignee "$FUNCTION_PRINCIPAL_ID" \
    --output table \
    --query "[].{Role:roleDefinitionName, Scope:scope}"

echo ""
echo "🚀 Function App is now ready to process VNet Flow Logs!"
echo "Next: Update your Event Grid subscription to use the Function App URL"