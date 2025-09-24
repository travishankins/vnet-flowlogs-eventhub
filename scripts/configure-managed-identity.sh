#!/usr/bin/env bash
set -euo pipefail

# Script to configure Managed Identity permissions for Logic App
# Run this after creating the infrastructure

### ── Variables (should match your setup-infrastructure.sh) ──────────────────
RG="LogicAppArea"
EH_NAMESPACE="evh-logs-demo"
STORAGE_ACCOUNT="YOUR_STORAGE_ACCOUNT_NAME"  # Replace with your actual storage account name
LOGIC_APP_NAME="YOUR_LOGIC_APP_NAME"  # Replace with your actual Logic App name
### ────────────────────────────────────────────────────────────────────────

echo "== Configuring Managed Identity for Logic App =="

# Get the Logic App's managed identity principal ID
LOGIC_APP_PRINCIPAL_ID=$(az logic workflow show \
  --resource-group "$RG" \
  --name "$LOGIC_APP_NAME" \
  --query "identity.principalId" \
  --output tsv)

echo "Logic App Principal ID: $LOGIC_APP_PRINCIPAL_ID"

# Get resource IDs
EH_NAMESPACE_ID=$(az eventhubs namespace show \
  --resource-group "$RG" \
  --name "$EH_NAMESPACE" \
  --query "id" \
  --output tsv)

STORAGE_ACCOUNT_ID=$(az storage account show \
  --resource-group "$RG" \
  --name "$STORAGE_ACCOUNT" \
  --query "id" \
  --output tsv)

echo "== Assigning Event Hub Data Sender role to Logic App =="
az role assignment create \
  --assignee "$LOGIC_APP_PRINCIPAL_ID" \
  --role "Azure Event Hubs Data Sender" \
  --scope "$EH_NAMESPACE_ID"

echo "== Assigning Storage Blob Data Reader role to Logic App =="
az role assignment create \
  --assignee "$LOGIC_APP_PRINCIPAL_ID" \
  --role "Storage Blob Data Reader" \
  --scope "$STORAGE_ACCOUNT_ID"

echo "✅ Managed Identity permissions configured successfully!"
echo
echo "Note: Role assignments may take a few minutes to propagate."
echo "You can now deploy the updated workflow.json that uses Managed Identity."