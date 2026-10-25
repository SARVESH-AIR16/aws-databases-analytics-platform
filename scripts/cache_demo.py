#!/usr/bin/env python3
"""Offline cache behavior illustration; not an AWS performance benchmark."""
from __future__ import annotations
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "data" / "sample" / "orders.json"


def validate_sample() -> None:
    payload = json.loads(SAMPLE.read_text(encoding="utf-8"))
    records = payload if isinstance(payload, list) else payload.get("orders", [])
    if not isinstance(records, list) or not records:
        raise ValueError("Sample orders must be a non-empty JSON list or contain a non-empty 'orders' list.")
    required = {"customer_id", "order_id", "status", "created_at"}
    for index, item in enumerate(records):
        if not isinstance(item, dict):
            raise ValueError(f"Record {index} is not a JSON object.")
        missing = sorted(required - set(item))
        if missing:
            raise ValueError(f"Record {index} is missing required fields: {', '.join(missing)}")
    print(f"Validated {len(records)} sample order records for the cache demo.")


def simulate() -> None:
    source = {
        "order-1001": {"status": "PAID", "total": 1299},
        "order-1002": {"status": "PENDING", "total": 499},
        "order-1003": {"status": "SHIPPED", "total": 899},
    }
    requests = ["order-1001", "order-1002", "order-1001", "order-1003", "order-1001", "order-1002"]
    cache = {}
    hits = misses = 0
    start = time.perf_counter()
    for key in requests:
        if key in cache:
            hits += 1
            _value = cache[key]
        else:
            misses += 1
            cache[key] = source.get(key)
    elapsed_ms = (time.perf_counter() - start) * 1000
    total = hits + misses
    print("Offline in-memory cache simulation (not an AWS service benchmark)")
    print(f"Requests: {total}")
    print(f"Hits: {hits}")
    print(f"Misses: {misses}")
    print(f"Hit ratio: {hits / total:.1%}")
    print(f"Local simulation elapsed: {elapsed_ms:.3f} ms")
    print("Use a deployed endpoint and realistic workload for AWS performance evidence.")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in {"validate-sample", "simulate"}:
        print("Usage: python3 scripts/cache_demo.py validate-sample|simulate", file=sys.stderr)
        sys.exit(2)
    try:
        validate_sample() if sys.argv[1] == "validate-sample" else simulate()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
