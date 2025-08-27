#!/usr/bin/env python3
"""
Forward Splunk logs to Microsoft Sentinel securely.
"""

import requests, json

splunk_data = [{"event": "failed_login", "user": "jsmith"}]

for event in splunk_data:
    requests.post("https://sentinel.example.com/api/logs", json=event)
