#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
kyber-rotation-scheduler.py
Simulate a Kyber (KEM) key rotation policy for services using hybrid TLS.
- Generates a rotation calendar based on policy (interval days, overlap window)
- Produces an audit log and next rotation window

Note: This is a scheduler simulation for portfolio demonstration; it does not perform crypto.

Usage:
  python kyber-rotation-scheduler.py --services api1 api2 --interval-days 7 --overlap-hours 2 --out schedule.json
"""

import argparse, json
from datetime import datetime, timedelta

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--services", nargs="+", required=True)
    ap.add_argument("--interval-days", type=int, default=7)
    ap.add_argument("--overlap-hours", type=int, default=2)
    ap.add_argument("--out", default="schedule.json")
    args = ap.parse_args()

    now = datetime.utcnow()
    items = []
    for s in args.services:
        start = now
        end = start + timedelta(days=args.interval_days)
        overlap_start = end - timedelta(hours=args.overlap_hours)
        items.append({
            "service": s,
            "current_kem": "Kyber768",
            "policy": {"interval_days": args.interval_days, "overlap_hours": args.overlap_hours},
            "window": {"start": start.isoformat()+"Z", "end": end.isoformat()+"Z"},
            "overlap_window": {"start": overlap_start.isoformat()+"Z", "end": end.isoformat()+"Z"},
            "next_rotation_at": end.isoformat()+"Z"
        })

    out = {"generated": now.isoformat()+"Z", "items": items}
    json.dump(out, open(args.out,"w"), indent=2)
    print(json.dumps({"services": len(items), "out": args.out}))

if __name__ == "__main__":
    main()
