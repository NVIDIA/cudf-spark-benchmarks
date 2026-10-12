# NVIDIA cuDF plugin for Apache Spark Benchmarks

A repo for Spark related benchmark sets and utilities using the 
[NVIDIA cuDF plugin for Apache Spark](https://github.com/NVIDIA/cudf-spark). 

## Benchmark sets:
- [NVIDIA Decision Support ( NDS )](./nds/)
- [NVIDIA Decision Support-H ( NDS-H )](./nds-h/)

Please see README in each benchmark set for more details including building instructions and usage
descriptions.

## Utilities

- [Portable YARN resource cost](./yarn-resource-cost/) attributes Spark
  application worker consumption from Spark and YARN logs across EMR,
  Dataproc, and on-premises deployments.


### Input statistics

Both NDS and NDS-H power drivers accept `--analyze none|table|column`.
This opt-in mode creates a fresh isolated in-memory catalog for each invocation;
`none` uses temporary views and collects no statistics, `table` computes table
statistics, and `column` runs `COMPUTE STATISTICS FOR ALL COLUMNS`. Statistics
are recomputed each invocation. Existing behavior, including `--analyze_tables`,
is unchanged when `--analyze` is omitted.

Use `--json_summary_folder` with this option. File-backed inputs are required;
Spark Connect, an existing driver session, custom catalogs, external Hive,
and combining `--analyze` with `--analyze_tables` are rejected. With NDS
`--cutoff_date`, catalog tables and their statistics include only the selected
fact partitions through the cutoff, plus NULL partitions. Dimensions remain
complete. The input directories are not modified.

The separate `statistics/analyze-cost.json` under the summary folder records
`mode`, total `duration_ms`, and per-table `duration_ms`. The CSV keeps its
existing columns and adds a `Statistics Time` row in milliseconds only when
`--analyze` is specified. Analysis precedes `Power Start Time`, so query times
and `Power Test Time` exclude it. `Total Time` remains the full application
wall time, including setup and statistics; add statistics cost separately when
comparing query totals.
