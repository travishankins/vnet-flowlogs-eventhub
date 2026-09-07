import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("flowlogs_handler", ROOT / "function-app" / "__init__.py")
handler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(handler)


class HandlerTests(unittest.TestCase):
    def invoke(self, events):
        request = Mock()
        request.get_json.return_value = events
        return handler.main(request)

    @patch.object(handler, "process_flow_log_event", return_value=False)
    def test_failure_is_retryable(self, process):
        response = self.invoke([{"eventType": "Microsoft.Storage.BlobCreated"}])
        self.assertEqual(response.status_code, 503)

    @patch.object(handler, "process_flow_log_event", side_effect=[True, False])
    def test_partial_failure_is_retryable(self, process):
        response = self.invoke([{"eventType": "Microsoft.Storage.BlobCreated"}] * 2)
        self.assertEqual(response.status_code, 503)

    @patch.object(handler, "process_flow_log_event", return_value=True)
    def test_success(self, process):
        self.assertEqual(self.invoke([{"eventType": "Microsoft.Storage.BlobCreated"}]).status_code, 200)

    @patch.object(handler, "process_flow_log_event")
    def test_subscription_validation(self, process):
        response = self.invoke([{
            "eventType": "Microsoft.EventGrid.SubscriptionValidationEvent",
            "data": {"validationCode": "validation-code"},
        }])
        self.assertEqual(json.loads(response.get_body()), {"validationResponse": "validation-code"})
        process.assert_not_called()

    def test_malformed_events(self):
        for events in ({}, [], [None], ["invalid"]):
            with self.subTest(events=events):
                self.assertEqual(self.invoke(events).status_code, 400)

    def test_function_layout(self):
        config_path = ROOT / "function-app" / "flowlogs" / "function.json"
        config = json.loads(config_path.read_text())
        self.assertTrue((config_path.parent / config["scriptFile"]).is_file())
        self.assertEqual(config["bindings"][0]["authLevel"], "function")


if __name__ == "__main__":
    unittest.main()
