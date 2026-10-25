-- Run in the optional private Redshift cluster only after the analytics S3
-- bucket, Glue database and crawler have been created and the crawler has run.
-- The cluster's default IAM role is configured by Terraform for read-only access
-- to the Parquet prefix and Glue Catalog metadata.

CREATE EXTERNAL SCHEMA IF NOT EXISTS spectrum_analytics
FROM DATA CATALOG
DATABASE 'dba_analytics_lake'
IAM_ROLE default
CREATE EXTERNAL DATABASE IF NOT EXISTS;

SELECT
  status,
  COUNT(*) AS order_count,
  ROUND(SUM(order_total), 2) AS total_order_value
FROM spectrum_analytics.orders
GROUP BY status
ORDER BY status;
