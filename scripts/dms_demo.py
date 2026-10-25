#!/usr/bin/env python3
"""Offline validator and dry-run summary for Module 8; never calls AWS."""
from __future__ import annotations

import json
from collections import Counter
from decimal import Decimal
from pathlib import Path
from datetime import datetime
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "data" / "sample" / "orders.json"
SCHEMA = ROOT / "data" / "migration" / "orders-schema.sql"
EXPECTED = {"order_id", "customer_id", "status", "created_at", "order_total", "currency"}


def load_orders() -> list[dict]:
    payload = json.loads(SAMPLE.read_text(encoding="utf-8"))
    if not isinstance(payload, list) or not payload:
        raise ValueError("sample orders must be a non-empty JSON array")
    seen: set[str] = set()
    for index, row in enumerate(payload, start=1):
        if not isinstance(row, dict):
            raise ValueError(f"order record {index} must be an object")
        missing = {"order_id", "customer_id", "status", "created_at", "order_total", "currency"} - set(row)
        if missing:
            raise ValueError(f"order record {index} is missing fields: {', '.join(sorted(missing))}")
        if not all(isinstance(row[k], str) and row[k] for k in ("order_id", "customer_id", "status", "created_at", "currency")):
            raise ValueError(f"order record {index} contains an empty/non-string identifier or status field")
        if row["order_id"] in seen:
            raise ValueError(f"duplicate order_id: {row['order_id']}")
        seen.add(row["order_id"])
        try:
            Decimal(str(row["order_total"]))
        except Exception as exc:
            raise ValueError(f"order record {index} has invalid order_total") from exc
    if not SCHEMA.is_file():
        raise ValueError("migration source schema file is missing")
    schema_sql = SCHEMA.read_text(encoding="utf-8")
    for token in ("CREATE TABLE IF NOT EXISTS public.orders", "order_id", "order_total", "ON CONFLICT (order_id) DO NOTHING"):
        if token not in schema_sql:
            raise ValueError(f"migration SQL is missing expected token: {token}")
    return payload


def validate_sample() -> None:
    rows = load_orders()
    counts = Counter(row["status"] for row in rows)
    print(f"PASS: validated {len(rows)} synthetic orders and unique order IDs; no AWS API was called.")
    print("Status counts: " + ", ".join(f"{key}={counts[key]}" for key in sorted(counts)))
    print("Destination contract: Parquet full-load under data/dms-migration/public/orders/")


def simulate() -> None:
    rows = load_orders()
    counts = Counter(row["status"] for row in rows)
    print("Offline DMS full-load dry run (not an AWS migration benchmark)")
    print(f"Source table: public.orders; synthetic rows: {len(rows)}")
    print("Status counts: " + ", ".join(f"{key}={counts[key]}" for key in sorted(counts)))
    print("Expected S3 location: s3://<analytics-bucket>/data/dms-migration/public/orders/")
    print("No PostgreSQL connection, DMS task, Parquet export, or AWS API was executed.")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in {"validate-sample", "simulate"}:
        print("Usage: python3 scripts/dms_demo.py validate-sample|simulate", file=sys.stderr)
        sys.exit(2)
    try:
        validate_sample() if sys.argv[1] == "validate-sample" else simulate()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
