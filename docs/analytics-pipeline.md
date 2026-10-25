# Analytics pipeline — target design

1. Produce synthetic sample records locally.
2. Store sample files in S3 in a columnar format such as Parquet when the storage/query stage is implemented.
3. Register dataset metadata with Glue Data Catalog.
4. Query the S3 dataset with Athena.
5. Add Kinesis Data Streams and Firehose only after the batch path works and current costs are reviewed.
6. Treat Redshift as an optional later milestone.
7. Document row counts, schema, query examples, data quality checks, and cleanup steps.

No pipeline resources are deployed by this scaffold.
