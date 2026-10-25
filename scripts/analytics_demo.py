#!/usr/bin/env python3
"""Local sample-order validator and optional Parquet generator; no AWS APIs."""
from __future__ import annotations

from datetime import datetime
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "data" / "sample" / "orders.json"
OUTPUT = ROOT / "data" / "analytics" / "generated" / "orders" / "part-00000.parquet"
REQUIRED = {"customer_id", "order_id", "status", "created_at", "order_total", "currency"}
ALLOWED_STATUS = {"PENDING", "PAID", "SHIPPED", "CANCELLED"}


def load_and_validate() -> list[dict]:
    try:
        records = json.loads(SAMPLE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"Cannot read sample orders: {exc}") from exc
    if not isinstance(records, list) or not records:
        raise ValueError("Sample data must be a non-empty JSON array.")
    seen: set[tuple[str, str]] = set()
    for idx, record in enumerate(records, start=1):
        if not isinstance(record, dict):
            raise ValueError(f"Record {idx} must be an object.")
        missing = REQUIRED - record.keys()
        if missing:
            raise ValueError(f"Record {idx} is missing fields: {', '.join(sorted(missing))}")
        key = (record["customer_id"], record["order_id"])
        if not all(isinstance(value, str) and value for value in key):
            raise ValueError(f"Record {idx} customer_id and order_id must be non-empty strings.")
        if key in seen:
            raise ValueError(f"Duplicate customer/order key at record {idx}: {key}")
        seen.add(key)
        if record["status"] not in ALLOWED_STATUS:
            raise ValueError(f"Record {idx} has unsupported status: {record['status']}")
        if not isinstance(record["order_total"], (int, float)) or isinstance(record["order_total"], bool) or record["order_total"] < 0:
            raise ValueError(f"Record {idx} order_total must be a non-negative number.")
        if not isinstance(record["currency"], str) or len(record["currency"]) != 3:
            raise ValueError(f"Record {idx} currency must be a three-letter code.")
        if not isinstance(record["created_at"], str):
            raise ValueError(f"Record {idx} created_at must be an ISO-8601 string.")
        try:
            created = datetime.fromisoformat(record["created_at"].replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError(f"Record {idx} created_at is not valid ISO-8601.") from exc
        if created.tzinfo is None:
            raise ValueError(f"Record {idx} created_at must include a timezone.")
    return records


def validate_sample() -> None:
    records = load_and_validate()
    totals_by_status: dict[str, float] = {}
    for record in records:
        totals_by_status[record["status"]] = totals_by_status.get(record["status"], 0.0) + float(record["order_total"])
    print(f"PASS: validated {len(records)} sample orders; no AWS API was called.")
    for status, amount in sorted(totals_by_status.items()):
        print(f"  {status}: {sum(1 for row in records if row['status'] == status)} orders, total {amount:.2f}")


def build_parquet() -> None:
    records = load_and_validate()
    try:
        import pyarrow as pa
        import pyarrow.parquet as pq
    except ImportError as exc:
        raise RuntimeError("Parquet generation needs PyArrow. Install it with: python3 -m pip install pyarrow") from exc

    normalized = []
    for record in records:
        row = dict(record)
        row["created_at"] = datetime.fromisoformat(row["created_at"].replace("Z", "+00:00"))
        row["order_total"] = float(row["order_total"])
        normalized.append(row)
    schema = pa.schema([
        pa.field("customer_id", pa.string()),
        pa.field("order_id", pa.string()),
        pa.field("status", pa.string()),
        pa.field("created_at", pa.timestamp("us", tz="UTC")),
        pa.field("order_total", pa.float64()),
        pa.field("currency", pa.string()),
    ])
    table = pa.Table.from_pylist(normalized, schema=schema)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pq.write_table(table, OUTPUT, compression="snappy")
    print(f"Created local Parquet file: {OUTPUT.relative_to(ROOT)}")
    print("This is a local file only. Upload it to the approved S3 prefix only after deployment approval.")


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"validate-sample", "build-parquet"}:
        print("Usage: python3 scripts/analytics_demo.py validate-sample|build-parquet", file=sys.stderr)
        return 2
    try:
        validate_sample() if sys.argv[1] == "validate-sample" else build_parquet()
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
