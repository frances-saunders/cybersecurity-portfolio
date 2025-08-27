#!/usr/bin/env python3
"""
Normalize threat intel feeds and push into Sentinel/Splunk.
"""

import requests, json

feed_url = "https://threatfeed.example.com/latest.json"
data = requests.get(feed_url).json()

for entry in data["indicators"]:
    print(f"Pushing indicator {entry['ioc']} -> Sentinel/Splunk API")
