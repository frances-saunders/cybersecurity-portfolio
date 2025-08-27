#!/usr/bin/env python3
"""
Convert compliance scan outputs into executive-readable summary.
"""

import pandas as pd

df = pd.read_csv("nist-evidence.csv")
summary = df.groupby("ComplianceState").size()

print("Compliance Report:")
print(summary)
