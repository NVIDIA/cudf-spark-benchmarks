# Benchmarking custom datasets

Use the NDS power driver to benchmark your own SQL against Parquet data. Supply
three inputs:

- A dataset root containing your Parquet tables.
- A JSON manifest identifying which tables to load.
- A SQL stream that queries those tables.

The manifest supplies the table names and optional date-partition metadata in
place of the built-in TPC-DS definitions. Spark infers the schemas from your
Parquet files. The driver provides query execution, result writing and statistics
collection.

Choose one way to define the dataset. Without a manifest, `--input_format`
selects the format for the standard NDS tables and defaults to Parquet. With
`--dataset_manifest`, the manifest selects your tables; currently these must be
Parquet. The two options cannot be supplied together, even with an explicit
`--input_format parquet`. Run options such as `--app_name`, `--cutoff_date` and
`--analyze` still apply.

## Dataset layout

The `input_prefix` argument points to your dataset root. Each table listed in the
manifest is loaded from a subdirectory with the same name and registered under
that name for SQL queries. For example, a `purchases` entry loads
`<input_prefix>/purchases` and makes it available as `purchases`.

Pass the manifest separately with `--dataset_manifest PATH`. It describes existing
data; it does not contain or generate it. The file can live alongside the dataset
or elsewhere accessible to the Spark driver. For example:

```text
dataset/
  purchases/
  accounts/
metadata/
  workload.json
```

For this layout, save the following as `metadata/workload.json`:

```json
{
  "tables": {
    "purchases": {},
    "accounts": {"date_partition_column": null}
  }
}
```

The `tables` object must be nonempty. Each table name must start with an ASCII
letter or underscore and contain only ASCII letters, digits or underscores. Names
must be distinct ignoring case: `Foo` and `foo` conflict even when
`spark.sql.caseSensitive=true`, because Hive catalogs store lowercase table names.
Only listed tables are registered.

Each table entry is an object accepting `date_partition_column` and the optional
`partition_columns` list. Other table-entry keys are errors, so misspelled loading
options cannot silently disable a cutoff. Additional top-level metadata, such as
`parameters`, is permitted and does not affect loading.

Omitting `date_partition_column` or setting it to `null` means no cutoff filtering
for that table. Spark infers column schemas from the Parquet files. For cutoff
loading, `partition_columns` can list every directory partition column in physical
order. A non-null `date_partition_column` must appear in this list when the list
is supplied. Column names must match the directory names exactly, including case;
duplicate column names are rejected ignoring case. Without the list, the driver
discovers the partition layout from the directories.

Empty stray folders beneath partition leaves are allowed and do not change the
selected rows. Store data files directly in the partition leaf directories.
Files inside ordinary nested folders are not supported: Spark can load them in
temporary views but omit them from catalog tables created for `--analyze`, so
enabling analysis can change the rows returned. The driver does not perform
extra directory listings to detect this layout.

An unqualified path such as `/path/to/workload.json` or `metadata/workload.json`
is a driver-local file, regardless of Spark's default filesystem. An existing
local filename containing a colon, such as `workload:v2.json`, is also read locally.
A URI such as
`file:///path/to/workload.json`, `hdfs:///metadata/workload.json` or
`s3a://bucket/metadata/workload.json` uses the corresponding Hadoop filesystem;
its connector and credentials must be available to the driver. Missing or invalid
manifests are errors.

Manifest loading requires file-backed Parquet inputs and a regular Spark
session, rather than Spark Connect. It does not apply to external Hive tables,
Iceberg or Delta inputs. Without `--dataset_manifest`, the ordinary NDS loading
behavior is unchanged. The driver does not discover metadata files in the input
directory.

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

`query1.tpl` is a label in the stream marker, not a file you need to supply.
Use a distinct label for each query; `query1` becomes its name in reports and
result paths.

Without `--cutoff_date`, every listed table is loaded in full and no
`date_dim` table is required. By default tables are temporary views.
`--analyze table|all_columns` registers catalog tables and collects statistics
for the same listed tables. Analysis fails if a listed table name already exists
in the catalog, to avoid analyzing data from an earlier run. When
`--json_summary_folder` is provided, analysis costs are saved separately in
`statistics/analyze-cost.json`.

## Date cutoffs

To filter a listed table by `--cutoff_date YYYY-MM-DD`, set its
`date_partition_column` to a nonempty column name. It must identify a directory
partition column, which can appear at any level in a table partitioned by
multiple columns. The driver recognizes these partition values:

- Calendar dates, such as `purchase_date=2001-07-01`, are compared directly
  with the cutoff. This layout needs no `date_dim` table.
- Integer date keys, such as `order_day=123`, are resolved using `date_dim`.
  For this layout the manifest must list `date_dim`, containing `d_date_sk`
  and `d_date`. `d_date_sk` must have an integral Spark type or contain integral
  decimal values; string keys are not supported. Each key maps to a calendar date in `d_date`, which must have
  Spark DATE or STRING type containing `YYYY-MM-DD` values. TIMESTAMP values
  are not supported and produce an error rather than being truncated to dates.
  Keys and dates must be non-null, and a key must not map to conflicting dates.

The driver includes partitions mapped to dates on or before the cutoff, plus
NULL-date partitions. NULL partitions have no known date; retaining them does
not imply they are earlier than the cutoff. Every filtered table must have at
least one dated partition selected. Tables without a date-partition column,
including `date_dim` itself, remain complete. Analysis uses only the selected
partitions. For catalog analysis, partition values containing quotes or backslashes
require `spark.sql.legacy.keepPartitionSpecAsStringLiteral=false` (Spark's default).
An incompatible setting is rejected before the table is created.
Partition values and source paths are registered literally: SQL variable
substitution is temporarily disabled during registration and restored afterward.

For example, both `purchases/region=west/purchase_date=2001-07-01/` and
`purchases/purchase_date=2001-07-01/region=west/` work with
`"date_partition_column": "purchase_date"`. Each table must use one consistent
partition order. The cutoff selects dates while retaining every region within
each selected date. Other partition columns remain available to SQL queries.

For the first layout, the optional metadata is:

```json
{
  "date_partition_column": "purchase_date",
  "partition_columns": ["region", "purchase_date"]
}
```

For the second layout, reverse the list to `["purchase_date", "region"]`.
Providing the complete order lets the driver stop listing directories once it
reaches a leaf partition. This avoids a separate listing of every selected leaf,
which can be expensive on cloud storage. Without this metadata, discovery remains
available. The built-in NDS tables already have known partition layouts and do
not require a manifest for this optimization.

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
