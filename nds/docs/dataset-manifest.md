# Custom datasets

The NDS power driver can run a custom SQL stream against Parquet tables selected
by a dataset manifest. This reuses its query execution, result writing and
statistics collection without requiring TPC-DS table names or schemas.

## Dataset layout

Keep one subdirectory per listed table under the input root. Select a separate
JSON manifest with `--dataset_manifest PATH`; its name and location are arbitrary:

```text
dataset/
  purchases/
  accounts/
metadata/
  workload.json
```

For example:

```json
{
  "tables": {
    "purchases": {},
    "accounts": {"date_partition_column": null}
  }
}
```

The `tables` object must be nonempty. Each table entry is an object; omitting
`date_partition_column` or setting it to `null` means no cutoff filtering for
that table. Only listed tables are registered. Spark infers column schemas and
existing partitions from the Parquet files.

An unqualified path such as `/path/to/workload.json` or `metadata/workload.json`
is a driver-local file, regardless of Spark's default filesystem. A URI such as
`file:///path/to/workload.json`, `hdfs:///metadata/workload.json` or
`s3a://bucket/metadata/workload.json` uses the corresponding Hadoop filesystem;
its connector and credentials must be available to the driver. Missing or invalid
manifests are errors.

Manifest loading requires file-backed Parquet inputs and a classic Spark
session. It does not apply to Spark Connect, external Hive tables, Iceberg or
Delta inputs. Without `--dataset_manifest`, the ordinary NDS loading behavior is
unchanged. The driver does not discover metadata files in the input directory.

## Run a query stream

Supply the dataset root and your SQL stream using the driver's existing arguments:

```bash
spark-submit nds/nds_power.py \
  --dataset_manifest /path/to/metadata/workload.json \
  --app_name 'Custom workload' \
  --output_prefix /path/to/results \
  /path/to/dataset /path/to/queries.sql /path/to/times.csv
```

Supply the SQL stream yourself using the usual NDS query markers and the
manifest's table names. The driver does not rewrite SQL predicates; choose date
windows appropriate for your dataset and cutoff:

```sql
-- start query 1 in stream 0 using template query1.tpl
SELECT p.purchase_id, a.category
FROM purchases p JOIN accounts a ON p.account_id = a.account_id;
-- end query 1 in stream 0 using template query1.tpl
```

Without `--cutoff_date`, every listed table is loaded in full and no
`date_dim` table is required. By default tables are temporary views.
`--analyze table|all_columns` registers catalog tables and collects statistics
for the same listed tables. Analysis requires fresh catalog table names; it does
not reuse existing tables. When `--json_summary_folder` is provided, analysis
costs are saved separately in `statistics/analyze-cost.json`.

## Date cutoffs

To filter a listed table by `--cutoff_date YYYY-MM-DD`, set its
`date_partition_column` to a nonempty column name. The table must use a single
directory partition level. The driver recognizes these partition values:

- Calendar dates, such as `purchase_date=2001-07-01`, are compared directly
  with the cutoff. This layout needs no `date_dim` table.
- Integer date keys, such as `order_day=123`, are resolved using `date_dim`.
  For this layout the manifest must list `date_dim`, containing `d_date_sk`
  and `d_date`. Each integer key maps to a calendar date in `d_date`; dates
  may be Spark date values or `YYYY-MM-DD` strings. Keys and dates must be
  non-null, and a key must not map to conflicting dates.

The driver includes partitions mapped to dates on or before the cutoff, plus
NULL-date partitions. NULL partitions have no known date; retaining them does
not imply they are earlier than the cutoff. Every filtered table must have at
least one dated partition selected. Tables without a date-partition column,
including `date_dim` itself, remain complete. Analysis uses only the selected
partitions.

For Parquet partitioned by a DATE column, the manifest entries can be:

```json
{
  "tables": {
    "purchases": {"date_partition_column": "purchase_date"},
    "accounts": {}
  }
}
```

Run that dataset through a cutoff and save statistics costs with:

```bash
spark-submit nds/nds_power.py \
  --dataset_manifest /path/to/metadata/workload.json \
  --app_name 'Custom workload with cutoff' \
  --cutoff_date 2001-07-01 \
  --analyze all_columns \
  --json_summary_folder /path/to/summaries \
  --output_prefix /path/to/results \
  /path/to/dataset /path/to/queries.sql /path/to/times.csv
```
