#!/usr/bin/env python3
"""Offline Module 7 sample validation and stream-to-S3 delivery simulation.

This script never calls AWS. It validates synthetic NDJSON and illustrates
expected S3 prefix behavior; it is not a throughput or service benchmark.
"""
from __future__ import annotations

from collections import Counter
from datetime import datetime
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "data" / "streaming" / "sample-orders.ndjson"
REQUIRED = {"event_id", "event_type", "order_id", "customer_id", "status", "amount", "currency", "occurred_at"}
ALLOWED_STATUSES = {"PENDING", "PAID", "SHIPPED", "CANCELLED"}


def load_events() -> list[dict[str, object]]:
    try:
        lines = SAMPLE.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ValueError(f"Cannot read sample event file {SAMPLE}: {exc}") from exc
    if not lines:
        raise ValueError("Sample NDJSON file is empty")

    events: list[dict[str, object]] = []
    seen: set[str] = set()
    for line_number, line in enumerate(lines, start=1):
        try:
            value = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Line {line_number} is not valid JSON: {exc}") from exc
        if not isinstance(value, dict):
            raise ValueError(f"Line {line_number} must be a JSON object")
        missing = REQUIRED - value.keys()
        if missing:
            raise ValueError(f"Line {line_number} is missing fields: {', '.join(sorted(missing))}")
        event_id = value["event_id"]
        if not isinstance(event_id, str) or not event_id.strip():
            raise ValueError(f"Line {line_number} has an invalid event_id")
        if event_id in seen:
            raise ValueError(f"Duplicate event_id {event_id!r}")
        seen.add(event_id)
        if value["event_type"] != "ORDER_STATUS_CHANGED":
            raise ValueError(f"Line {line_number} has an unsupported event_type")
        if value["status"] not in ALLOWED_STATUSES:
            raise ValueError(f"Line {line_number} has an unsupported order status")
        amount = value["amount"]
        if isinstance(amount, bool) or not isinstance(amount, (int, float)) or amount <= 0:
            raise ValueError(f"Line {line_number} amount must be a positive number")
        if value["currency"] != "INR":
            raise ValueError(f"Line {line_number} currency must be INR for this sample")
        if not all(isinstance(value[key], str) and value[key].strip() for key in ("order_id", "customer_id")):
            raise ValueError(f"Line {line_number} order_id and customer_id must be non-empty strings")
        try:
            happened = datetime.fromisoformat(str(value["occurred_at"]).replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError(f"Line {line_number} occurred_at must be an ISO-8601 timestamp") from exc
        if happened.tzinfo is None:
            raise ValueError(f"Line {line_number} occurred_at must include a timezone")
        events.append(value)
    return events


def validate_sample() -> None:
    events = load_events()
    print(f"PASS: validated {len(events)} synthetic NDJSON events; no AWS API was called.")
    print("Event statuses: " + ", ".join(f"{status}={count}" for status, count in sorted(Counter(str(e["status"]) for e in events).items())))


def simulate() -> None:
    events = load_events()
    totals = Counter(str(event["status"]) for event in events)
    print("Offline Kinesis -> Firehose -> S3 simulation (not an AWS benchmark)")
    print(f"Events validated: {len(events)}")
    print(f"Unique event IDs: {len({str(e['event_id']) for e in events})}")
    print("Aggregated status counts: " + ", ".join(f"{key}={value}" for key, value in sorted(totals.items())))
    print("Illustrative success prefix: s3://<analytics-bucket>/data/streaming/year=YYYY/month=MM/day=DD/")
    print("Illustrative error prefix: s3://<analytics-bucket>/data/streaming-errors/<error-type>/...")
    print("No AWS APIs were called; compression, buffering, and delivery were not executed.")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in {"validate-sample", "simulate"}:
        print("Usage: python3 scripts/streaming_demo.py validate-sample|simulate", file=sys.stderr)
        sys.exit(2)
    try:
        validate_sample() if sys.argv[1] == "validate-sample" else simulate()
    except (OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
