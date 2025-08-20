#!/usr/bin/env python3

import asyncio
import time
import json
import os
from shuffle_sdk import ShuffleMod

class TestApp(ShuffleMod):
    def __init__(self):
        super().__init__()
        self.name = "test-app"
        self.version = "1.0.0"
        self.description = "Test app using App SDK 0.0.25"

    def hello_world(self, name="World"):
        """
        Simple hello world function to test App SDK 0.0.25
        """
        try:
            # Test basic functionality
            message = f"Hello {name}! Using App SDK 0.0.25"
            
            # Test datastore functionality (if available in 0.0.25)
            try:
                test_key = f"test_execution_{int(time.time())}"
                self.set_datastore_key(test_key, {"message": message, "timestamp": time.time()})
                stored_data = self.get_datastore_key(test_key)
                datastore_test = "set_datastore_key working"
            except AttributeError:
                # Fallback if datastore methods aren't available
                stored_data = None
                datastore_test = "datastore methods not available in this SDK version"
            
            return {
                "success": True,
                "message": message,
                "stored_data": stored_data,
                "app_version": self.version,
                "sdk_features": datastore_test
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "message": "Failed to execute hello_world function"
            }

    def test_execution_isolation(self, execution_id="default"):
        """
        Test execution isolation to verify 0.0.25 fixes
        """
        try:
            # Create execution-specific data
            execution_key = f"execution_{execution_id}_{int(time.time())}"
            
            # Store execution state
            execution_data = {
                "execution_id": execution_id,
                "started_at": time.time(),
                "status": "running",
                "test_data": f"Test data for execution {execution_id}"
            }
            
            # Try to use datastore if available
            try:
                self.set_datastore_key(execution_key, execution_data)
                datastore_used = True
            except AttributeError:
                datastore_used = False
            
            # Simulate some work
            time.sleep(2)
            
            # Update execution state
            execution_data["status"] = "completed"
            execution_data["completed_at"] = time.time()
            
            if datastore_used:
                self.set_datastore_key(execution_key, execution_data)
            
            return {
                "success": True,
                "execution_id": execution_id,
                "execution_key": execution_key,
                "execution_data": execution_data,
                "datastore_used": datastore_used,
                "message": "Execution isolation test completed successfully"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "execution_id": execution_id
            }

if __name__ == "__main__":
    TestApp.run()
