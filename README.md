# VNet Flow Logs to Event Hub

This repository contains an Azure Logic App that processes VNet flow logs and forwards them to an Event Hub for analysis.

## Overview

The Logic App is triggered by Azure Event Grid notifications when new flow log blobs are created in storage. It then retrieves the blob content and sends it to an Event Hub for downstream processing.

## Architecture

1. **Trigger**: HTTP Request (receives Event Grid notifications)
2. **Condition**: Filters for `Microsoft.Storage.BlobCreated` events
3. **Action**: Retrieves blob content using Managed Identity
4. **Action**: Sends flow log data to Event Hub (`nsgflowhub`)

## Files

- `logicapp/workflow-consumption.json` - Logic App workflow for Consumption tier
- `logicapp/workflow-standard.json` - Logic App workflow for Standard tier
- `logicapp/README.md` - Workflow documentation and usage guide
- `scripts/setup-infrastructure.sh` - Automated Azure infrastructure deployment
- `scripts/configure-managed-identity.sh` - RBAC role assignment script
- `scripts/test-upload.sh` - Test script for end-to-end validation
- `CONFIGURATION.md` - **Required setup and configuration guide**

## Quick Start

1. **Deploy Infrastructure**: Run `scripts/setup-infrastructure.sh`
2. **Configure RBAC**: Run `scripts/configure-managed-identity.sh`  
3. **Import Workflow**: Deploy appropriate workflow JSON to Logic App
4. **⚠️ IMPORTANT**: Follow `CONFIGURATION.md` for required manual setup steps
5. **Test**: Configure and run `scripts/test-upload.sh`

## Manual Configuration Required

After running the setup scripts, you **must** manually configure the Event Hub connection in the Logic App. See `CONFIGURATION.md` for detailed steps - the Logic App will not work without this manual configuration.

## Deployment

1. Deploy the Logic App workflow using the Azure portal or ARM templates
2. Configure the Event Hub connection
3. Set up Event Grid subscriptions to trigger the workflow

## Testing

Use the test script in the `scripts/` folder to simulate storage events and verify the workflow functionality.