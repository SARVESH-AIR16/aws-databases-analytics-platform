#!/usr/bin/env python3
"""Local validation and explicit demo operations for the optional orders table."""
from __future__ import annotations

import argparse
import json
import sys
from decimal import Decimal
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SAMPLE_PATH = ROOT / "data" / "sample" / "orders.json"
REQUIRED_FIELDS = {"customer_id", "order_id", "status", "created_at", "order_total", "currency"}
ALLOWED_STATUSES = {"PENDING", "PAID", "CANCELLED"}


def load_sample() -> list[dict[str, Any]]:
    with SAMPLE_PATH.open(encoding="utf-8") as handle:
        data = json.load(handle, parse_float=Decimal)
    if not isinstance(data, list) or not data:
        raise ValueError("Sample orders must be a non-empty JSON array.")

    seen_keys: set[tuple[str, str]] = set()
    for index, item in enumerate(data):
        if not isinstance(item, dict):
            raise ValueError(f"Item {index} must be a JSON object.")
        missing = REQUIRED_FIELDS - item.keys()
        if missing:
            raise ValueError(f"Item {index} is missing fields: {', '.join(sorted(missing))}")
        for field in ("customer_id", "order_id", "status", "created_at", "currency"):
            if not isinstance(item[field], str) or not item[field].strip():
                raise ValueError(f"Item {index} field {field} must be a non-empty string.")
        if item["status"] not in ALLOWED_STATUSES:
            raise ValueError(f"Item {index} has unsupported status {item['status']!r}.")
        if not isinstance(item["order_total"], (int, Decimal)) or item["order_total"] < 0:
            raise ValueError(f"Item {index} order_total must be a non-negative number.")
        key = (item["customer_id"], item["order_id"])
        if key in seen_keys:
            raise ValueError(f"Duplicate sample key: {key}")
        seen_keys.add(key)
    return data


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("validate-sample", "seed", "get", "query-status", "cleanup-demo"))
    parser.add_argument("--profile", default="ghost-hunter-cli", help="AWS CLI profile (used only for AWS actions)")
    parser.add_argument("--region", default="ap-south-1")
    parser.add_argument("--table", default="db-analytics-orders")
    parser.add_argument("--customer-id", default="CUSTOMER#1001")
    parser.add_argument("--order-id", default="ORDER#2026-0001")
    parser.add_argument("--status", default="PAID", choices=sorted(ALLOWED_STATUSES))
    parser.add_argument("--confirm-demo-cleanup", action="store_true", help="required to delete only the known sample records")
    return parser


def main() -> int:
    args = make_parser().parse_args()
    try:
        sample = load_sample()
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    if args.action == "validate-sample":
        print(f"PASS: validated {len(sample)} sample orders; no AWS API was called.")
        return 0

    if args.action == "cleanup-demo" and not args.confirm_demo_cleanup:
        print("STOP: cleanup-demo requires --confirm-demo-cleanup.", file=sys.stderr)
        return 2

    try:
        import boto3
        from boto3.dynamodb.conditions import Key
    except ImportError:
        print("boto3 is required for AWS actions. Install with: python3 -m pip install boto3", file=sys.stderr)
        return 2

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    table = session.resource("dynamodb").Table(args.table)

    try:
        if args.action == "seed":
            for item in sample:
                table.put_item(Item=item)
            print(f"Wrote {len(sample)} synthetic records to {args.table} in {args.region}.")
        elif args.action == "get":
            response = table.get_item(Key={"customer_id": args.customer_id, "order_id": args.order_id})
            print(json.dumps(response.get("Item"), default=str, indent=2))
        elif args.action == "query-status":
            response = table.query(
                IndexName="status-created-index",
                KeyConditionExpression=Key("status").eq(args.status),
                Limit=25,
                ScanIndexForward=True,
            )
            print(json.dumps(response.get("Items", []), default=str, indent=2))
        elif args.action == "cleanup-demo":
            with table.batch_writer() as batch:
                for item in sample:
                    batch.delete_item(Key={"customer_id": item["customer_id"], "order_id": item["order_id"]})
            print(f"Deleted only the {len(sample)} known sample records from {args.table}.")
    except Exception as exc:  # boto3 exception types vary by failure mode
        print(f"AWS operation failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
