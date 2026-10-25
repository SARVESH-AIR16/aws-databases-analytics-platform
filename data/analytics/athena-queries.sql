-- Run in the db-analytics-wg Athena workgroup after uploading the sample Parquet
-- file and starting the optional Glue crawler. If the crawler assigns a different
-- table name, inspect Glue Catalog and substitute the actual table name.

-- Aggregate count and order value by status.
SELECT
  status,
  COUNT(*) AS order_count,
  ROUND(SUM(order_total), 2) AS total_order_value
FROM "dba_analytics_lake"."orders"
GROUP BY status
ORDER BY status;

-- Daily order totals. created_at is stored as a UTC timestamp in the Parquet file.
SELECT
  CAST(created_at AS DATE) AS order_date,
  COUNT(*) AS order_count,
  ROUND(SUM(order_total), 2) AS total_order_value
FROM "dba_analytics_lake"."orders"
GROUP BY CAST(created_at AS DATE)
ORDER BY order_date;
