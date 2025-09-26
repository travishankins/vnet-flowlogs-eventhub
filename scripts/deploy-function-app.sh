#!/bin/bash

# Deploy VNet Flow Logs Azure Function App
# This script creates and deploys the Function App version of the VNet Flow Logs processor

set -e

# Configuration (update these with your values)
SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
LOCATION="westcentralus"
RG="rg-vnet-flow-logs"
STORAGE_ACCOUNT="stfunctionapp$(openssl rand -hex 6)"
FUNCTION_APP="func-vnet-flowlogs-$(openssl rand -hex 4)"
EVENT_HUB_NAMESPACE="YOUR_EVENT_HUB_NAMESPACE"  # From setup-infrastructure.sh output
APP_INSIGHTS="appi-vnet-flowlogs-$(openssl rand -hex 4)"

echo "🚀 Deploying VNet Flow Logs Function App..."
echo "Resource Group: $RG"
echo "Function App: $FUNCTION_APP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Location: $LOCATION"
echo ""

# Set subscription
echo "📋 Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo "📁 Creating resource group..."
az group create --name "$RG" --location "$LOCATION" --tags Purpose=VNetFlowLogs Environment=Production

# Create storage account for Function App
echo "💾 Creating storage account for Function App..."
az storage account create \
    --resource-group "$RG" \
    --name "$STORAGE_ACCOUNT" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

# Create Application Insights
echo "📊 Creating Application Insights..."
az monitor app-insights component create \
    --app "$APP_INSIGHTS" \
    --location "$LOCATION" \
    --resource-group "$RG" \
    --kind web \
    --application-type web

# Get Application Insights instrumentation key
APPINSIGHTS_KEY=$(az monitor app-insights component show \
    --app "$APP_INSIGHTS" \
    --resource-group "$RG" \
    --query "instrumentationKey" \
    --output tsv)

# Create Function App with managed identity
echo "⚡ Creating Function App..."
az functionapp create \
    --resource-group "$RG" \
    --name "$FUNCTION_APP" \
    --storage-account "$STORAGE_ACCOUNT" \
    --consumption-plan-location "$LOCATION" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --assign-identity '[system]' \
    --app-insights "$APP_INSIGHTS" \
    --app-insights-key "$APPINSIGHTS_KEY" \
    --tags Purpose=VNetFlowLogs Environment=Production

# Configure Function App settings
echo "⚙️ Configuring Function App settings..."
az functionapp config appsettings set \
    --resource-group "$RG" \
    --name "$FUNCTION_APP" \
    --settings \
        "EVENT_HUB_NAMESPACE=$EVENT_HUB_NAMESPACE" \
        "EVENT_HUB_NAME=nsgflowhub" \
        "FUNCTIONS_WORKER_RUNTIME=python" \
        "AzureWebJobsFeatureFlags=EnableWorkerIndexing"

# Get Function App managed identity
echo "🔐 Getting Function App managed identity..."
FUNCTION_PRINCIPAL_ID=$(az functionapp show \
    --resource-group "$RG" \
    --name "$FUNCTION_APP" \
    --query "identity.principalId" \
    --output tsv)

echo "Function App Principal ID: $FUNCTION_PRINCIPAL_ID"

# Deploy function code
echo "📦 Deploying function code..."
cd function-app
func azure functionapp publish "$FUNCTION_APP" --python

echo ""
echo "✅ Function App deployment completed!"
echo ""
echo "📋 Deployment Summary:"
echo "  Function App: $FUNCTION_APP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Application Insights: $APP_INSIGHTS"
echo "  Managed Identity ID: $FUNCTION_PRINCIPAL_ID"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure RBAC permissions using configure-function-rbac.sh"
echo "2. Update Event Grid subscription to point to Function App URL"
echo "3. Test using test-function.sh"
echo ""
echo "📍 Function URL:"
FUNCTION_URL=$(az functionapp function show \
    --resource-group "$RG" \
    --name "$FUNCTION_APP" \
    --function-name "flowlogs" \
    --query "invokeUrlTemplate" \
    --output tsv 2>/dev/null || echo "https://${FUNCTION_APP}.azurewebsites.net/api/flowlogs")
echo "  $FUNCTION_URL"