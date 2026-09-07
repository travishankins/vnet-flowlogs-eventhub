# VNet Flow Logs to Event Hub

Forward stored Azure VNet flow-log data to Event Hub for downstream analysis.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat)](LICENSE)

[Quick Start](#quick-start) | [Configuration](#configuration) | [Validation](#validation) | [Guide](GUIDE.md)

## Overview

The repository contains Logic App and Python Function samples for blob-event processing.
The Function handler has local regression coverage; neither path is certified for a particular production workload.

## Prerequisites

- Azure storage, Event Grid, Event Hub, and a compatible processing host.
- Managed-identity data permissions and an authenticated webhook configuration.
- Python 3.12 for local tests; Bash and Azure deployment tools for the documented scripts.

## Quick Start

```text
git clone https://github.com/travishankins/vnet-flowlogs-eventhub.git
cd vnet-flowlogs-eventhub
python -m pip install -r function-app/requirements.txt
python -m unittest discover -s tests -v
```

Use an isolated Python environment. Review [configuration](CONFIGURATION.md) and the [project guide](GUIDE.md) before provisioning resources.

## Configuration

Set `EVENT_HUB_NAMESPACE` and optionally `EVENT_HUB_NAME` for the Function.
Its HTTP trigger requires a function key. Keep keys and webhook URLs private and confirm the storage and Event Hub role assignments.

## Validation

Tests cover processing outcomes, subscription validation, malformed event lists, and function layout.
Verify host discovery, actual flow-log arrival, retries, and Event Hub receipt in a nonproduction environment.

## Operations

Failed batches return a retryable error. Configure dead-lettering and monitor delivery failures.
Retain the previous artifact and subscription configuration; do not restore anonymous access as a rollback.

## Security and Limitations

Retries can duplicate already processed events; consumers must deduplicate.
The Function sends each blob as one message, so oversized blobs need a splitting design.
Review the older deployment scripts/runtime choices before use; the Logic App path needs separate validation.

## Documentation

- [Project guide](GUIDE.md): processing options, architecture, and deployment flow.
- [Configuration reference](CONFIGURATION.md): infrastructure and connections.
- [Function guide](function-app/README.md) and [Logic App guide](logicapp/README.md).

## Contributing

Open an issue or pull request with synthetic events and regression tests. Exclude webhook keys, private flow logs, and resource credentials.

## License

[MIT License](LICENSE).
