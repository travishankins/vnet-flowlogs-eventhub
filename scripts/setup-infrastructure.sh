#!/usr/bin/env bash
set -euo pipefail

# Non-interactive Azure CLI extension behavior (avoid prompts)
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true

# Make sure needed extensions are present
az extension add --name storage-preview --upgrade -y >/dev/null 2>&1 || true
az extension add --name logic --upgrade -y >/dev/null 2>&1 || true

### ── Edit these if you want ───────────────────────────────────────────────
SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID_HERE"    # Replace with your Azure subscription ID
LOCATION="westcentralus"
RG="LogicAppArea"

# Storage
STORAGE_NAME="stlog$RANDOM$RANDOM"
CONTAINER_NAME="insights-logs-networkflowlog"

# Event Hubs
EH_NAMESPACE="evh-logs-demo"
EH_NAME="nsgflowhub"
EH_PARTITIONS=2
EH_RETENTION_DAYS=1

# Logic App (Consumption)
LOGIC_APP_NAME="la-flowlogs-$RANDOM$RANDOM"
### ────────────────────────────────────────────────────────────────────────

echo "== Setting subscription =="
az account set --subscription "$SUBSCRIPTION_ID"

echo "== Ensuring resource group exists: $RG =="
az group create -n "$RG" -l "$LOCATION" -o none

echo "== Creating storage account: $STORAGE_NAME =="
az storage account create \
  -g "$RG" -n "$STORAGE_NAME" \
  -l "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --allow-shared-key-access false \
  --min-tls-version TLS1_2 \
  -o none

echo "== Creating blob container (management plane): $CONTAINER_NAME =="
az storage container-rm create \
  --resource-group "$RG" \
  --storage-account "$STORAGE_NAME" \
  --name "$CONTAINER_NAME" \
  --public-access off \
  -o none

echo "== Creating Event Hubs namespace: $EH_NAMESPACE =="
az eventhubs namespace create \
  -g "$RG" -n "$EH_NAMESPACE" \
  -l "$LOCATION" \
  --sku Standard \
  --capacity 1 \
  -o none

echo "== Creating Event Hub: $EH_NAME =="
az eventhubs eventhub create \
  -g "$RG" --namespace-name "$EH_NAMESPACE" \
  -n "$EH_NAME" \
  --partition-count "$EH_PARTITIONS" \
  -o none

echo "== Creating Logic App (Consumption): $LOGIC_APP_NAME =="
# IMPORTANT: Wrap your workflow body under a top-level 'definition' key
WORKFLOW_WRAPPED_JSON=$(cat <<'EOF'
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "triggers": {},
    "actions": {},
    "outputs": {}
  },
  "parameters": {}
}
EOF
)

az logic workflow create \
  -g "$RG" \
  -n "$LOGIC_APP_NAME" \
  -l "$LOCATION" \
  --definition "$WORKFLOW_WRAPPED_JSON" \
  -o none

echo
echo "✅ All set. Resources created:"
echo "  Resource group:           $RG"
echo "  Storage account:          $STORAGE_NAME"
echo "  Blob container:           $CONTAINER_NAME"
echo "  Event Hubs namespace:     $EH_NAMESPACE"
echo "  Event Hub (hub):          $EH_NAME"
echo "  Logic App:                $LOGIC_APP_NAME"
echo
echo "Next steps to complete in the Azure portal:"
echo "1) Logic App designer → build/import your workflow; create an Event Hub connection (namespace: $EH_NAMESPACE)."
echo "2) Storage → Events → + Event Subscription:"
echo "   • Endpoint type: Web Hook → paste Logic App trigger callback URL"
echo "   • Subject begins with: /blobServices/default/containers/$CONTAINER_NAME/blobs/"