#!/usr/bin/env python3

import json
import os
import sys
import requests

class ShuffleMod:
    def __init__(self):
        self.name = "unknown"
        self.version = "1.0.0"
        self.description = "Shuffle app"
        
        # Get environment variables
        self.base_url = os.getenv("BASE_URL", "http://shuffle-backend:5001")
        self.authorization = os.getenv("AUTHORIZATION", "")
        self.execution_id = os.getenv("EXECUTIONID", "")
        self.action = os.getenv("ACTION", "")
        
        # For datastore functionality
        self.datastore = {}

    def set_datastore_key(self, key, value):
        """Set a key-value pair in datastore"""
        try:
            # Simple in-memory storage for testing
            self.datastore[key] = value
            
            # Try to send to backend if available
            if self.base_url and self.authorization:
                url = f"{self.base_url}/api/v1/apps/datastore"
                headers = {"Authorization": self.authorization}
                data = {"key": key, "value": json.dumps(value)}
                requests.post(url, json=data, headers=headers, timeout=5)
                
            return True
        except Exception as e:
            print(f"Warning: Could not set datastore key: {e}")
            return False

    def get_datastore_key(self, key):
        """Get a value from datastore"""
        try:
            # Return from in-memory storage
            return self.datastore.get(key, None)
        except Exception as e:
            print(f"Warning: Could not get datastore key: {e}")
            return None

    @classmethod
    def run(cls):
        """Run the app"""
        app_instance = cls()
        
        # Get action from environment
        action = os.getenv("ACTION", "")
        if not action:
            print("No ACTION specified")
            sys.exit(1)
        
        # Get action parameters
        try:
            action_params = json.loads(os.getenv("ACTION_PARAMS", "{}"))
        except:
            action_params = {}
        
        # Execute the action
        if hasattr(app_instance, action):
            try:
                result = getattr(app_instance, action)(**action_params)
                print(json.dumps(result))
            except Exception as e:
                error_result = {
                    "success": False,
                    "error": str(e),
                    "action": action
                }
                print(json.dumps(error_result))
        else:
            error_result = {
                "success": False,
                "error": f"Action '{action}' not found",
                "available_actions": [method for method in dir(app_instance) if not method.startswith('_')]
            }
            print(json.dumps(error_result))
