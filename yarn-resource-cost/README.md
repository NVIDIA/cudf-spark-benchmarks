# Portable YARN resource cost

Spark elapsed time, task duration, YARN vcore-seconds, and Spark
executor-core-seconds answer different questions. None of them consistently
describes the fraction of worker nodes that YARN allocated to an application.
For example, `DefaultResourceCalculator` schedules by memory even when Spark
advertises several executor cores. Comparing raw vcore-seconds across clusters
can therefore undercount memory-heavy containers or compare unrelated YARN
accounting units.

This tool reconstructs container lifetimes and allocations from ResourceManager
logs, converts them into node-equivalent seconds, and optionally applies an
auditable hourly rate. Spark event logs select applications and provide names,
wall-clock duration, executor/container joins, and task-packing diagnostics;
they are not treated as the allocation ledger.

## Requirements

- Python 3.10 or newer. Installing the package also installs `zstandard` for
  compressed Spark event logs.
- Archived Spark rolling event logs.
- ResourceManager logs containing node registrations, allocations, terminal
  transitions, application summaries, and ResourceCalculator evidence.
- NodeManager logs are accepted only as incomplete fallback evidence.
- The provider CLI is needed only for remote discovery: AWS CLI for EMR,
  `gcloud` for Dataproc, or `hdfs` for on-premises HDFS paths.

## Accounting model

For a container lasting `ContainerSeconds` on a node:

```text
DefaultResourceCalculator:
  NodeShare = ContainerMemoryMB / NodeMemoryMB

DominantResourceCalculator:
  NodeShare = max(ContainerResource[r] / NodeResource[r]) for every r

NodeEquivalentSeconds = ContainerSeconds * NodeShare
```

## Python API

Install the subproject and its optional AWS dependency:

```bash
python3 -m pip install './yarn-resource-cost[aws]'
```

The application-scoped API accepts injected boto3 clients and returns resource
usage without imposing a pricing policy:

```python
import boto3

from yarn_resource_cost import (
    EmrApplicationUsageRequest,
    calculate_emr_application_usage,
)

session = boto3.Session(region_name="us-west-2")
usage = calculate_emr_application_usage(
    EmrApplicationUsageRequest(
        cluster_id="j-EXAMPLE",
        application_id="application_123_0001",
        event_log_uri="s3://example-bucket/spark-events/eventlog_v2_application_123_0001/",
        region="us-west-2",
    ),
    emr_client=session.client("emr"),
    s3_client=session.client("s3"),
)
print(usage.instance_seconds_by_type)
```

Injected S3 clients must provide the boto3 `GetObject` response's
`ContentLength` for legacy YARN archive reads. Without it, a log replaced after
listing cannot be distinguished from a truncated download; the API raises an
error rather than returning incomplete usage as a complete result.

ResourceManager and NodeManager logs are read from the cluster's EMR `LogUri`
archive by default, which the EMR log pusher updates about every five minutes.
Set `yarn_log_uri` to an S3 prefix holding this cluster's ResourceManager logs
when a log shipper uploads them sooner. Only file names containing
`hadoop-yarn-resourcemanager` are read from that prefix; when none exist yet,
the `LogUri` archive is used instead. The `calculate_yarn_job_cost.py` CLI
accepts the same prefix as `--yarn-log-shipper-uri`.

### Low-latency collection on persistent clusters

Use `rm_only=True` to account for one application from ResourceManager (RM)
logs without waiting for the NodeManager archive. Reuse a persistent local
`cache_dir` across calls so retries do not repeat completed downloads and
parsing. If a log shipper uploads RM logs sooner than EMR, point `yarn_log_uri`
at that cluster's S3 prefix:

```python
from pathlib import Path

usage = calculate_emr_application_usage(
    EmrApplicationUsageRequest(
        cluster_id="j-EXAMPLE",
        application_id="application_123_0001",
        event_log_uri="s3://example-bucket/spark-events/eventlog_v2_application_123_0001/",
        region="us-west-2",
        yarn_log_uri="s3://example-bucket/rm-logs/j-EXAMPLE/",
        rm_only=True,
    ),
    emr_client=session.client("emr"),
    s3_client=session.client("s3"),
    cache_dir=Path("/path/to/persistent/local/cache"),
)
```

This uses the `[aws]` installation above (boto3 and `zstandard`) and Python's
built-in SQLite. Under `cache_dir`, the tool keeps an RM index in
`rm-index-v1-*.sqlite3`, complete S3 event-log downloads in `s3-objects-v1/`,
and event metadata in `event-metadata-v1/`. Use private, writable local storage
with SQLite locking; the cache includes full event logs, has no automatic
eviction, and must not be removed while calls are running.
Permanent cache errors, such as a full disk or invalid SQLite schema, raise an
exception rather than a retryable result. Restore storage, or stop all callers
before deleting the disposable index so the next call can rebuild it.

If `usage.complete` is false and `usage.retryable` is true, retry later with
the same `cache_dir`. A specified `yarn_log_uri` is authoritative in this mode:
missing RM uploads return pending instead of falling back to EMR's archive.
Omit it to read RM logs from the cluster's EMR `LogUri` instead. A cold call
still reads RM history; a warm call still lists the RM prefix.

RM-only calls default to a 120-second `timeout_seconds` so one accounting
attempt can return retryable pending and resume from the cache. The original
mode remains unbounded unless you set a timeout. This does not limit the Spark
job's runtime or measured usage. The timeout is cooperative: it cannot stop
an in-flight S3 request, and each download must fit within an attempt. Set
bounded SDK timeouts separately; use smaller rolled logs or a larger
`timeout_seconds` if retries make no progress. INFO logs report phase timings,
downloaded bytes, and cache reuse.

`event_log_uri` accepts an S3 URI, a plain local path, or a local `file://` URI.
Passing a pre-materialized local file or rolling-event-log directory avoids an
S3 download; the selected event log is still streamed to extract accounting
metadata. Plain, `.lz4`, and `.zstd` event-log segments are supported. Individual
event records are limited to 64 MiB of decompressed data.

Incomplete archived logs return `complete=False` and indicate whether a later
retry can help. Missing summaries, allocations, terminal transitions, or node
registration metadata are retryable; contradictory or unsupported accounting
policies are not. Unreadable event-log segments are isolated to their owning
application: corrupt compressed data is retryable, while a missing decoder or
an oversized event record is not. Authentication and transport errors propagate
from boto3. The caller decides whether and how to translate instance-seconds
into currency.

Memory, vcores, `yarn.io/gpu`, and arbitrary numeric custom resources are
parsed generically. Heterogeneous node classes remain separate in structured
output and expressions such as:

```text
123.4 aws:ec2:r7a.24xlarge-seconds + 50.0 aws:ec2:g6.4xlarge-seconds
```

The calculator comes from archived scheduler evidence. There is intentionally
no calculator override. Built-in FairScheduler policies map to their actual
memory or dominant-resource calculators; ambiguous or conflicting policy
evidence is not guessed.

Final worker cost is emitted only for complete ledgers. Missing RM allocations,
terminal transitions, node capacities, application summaries, event-log
segments, node classifications, or price-catalog entries suppress final cost.

## Usage

Resource accounting is offline by default:

```bash
python3 yarn-resource-cost/yarn_resource_cost.py \
  --adapter emr \
  --event-log-root s3://example-bucket/run/spark-events/ \
  --pricing none
```

EMR live on-demand pricing includes EC2 and EMR worker components and records
the lookup result and timestamp:

```bash
python3 yarn-resource-cost/yarn_resource_cost.py \
  --adapter emr \
  --event-log-root s3://example-bucket/run/spark-events/ \
  --pricing live \
  --aws-profile example-profile \
  --aws-region us-west-2 \
  --output-json emr-cost.json
```

Dataproc accepts `gs://` Spark logs and exported RM/NM daemon logs. A node-class
map separates machine and accelerator shapes:

```bash
python3 yarn-resource-cost/yarn_resource_cost.py \
  --adapter dataproc \
  --event-log-root gs://example-bucket/spark-events/ \
  --yarn-log-root gs://example-bucket/cluster-daemon-logs/ \
  --node-class-map dataproc-node-classes.json \
  --pricing catalog \
  --price-catalog dataproc-prices.json
```

On-premises inputs can be directories, ZIP/tar archives, or HDFS paths:

```bash
python3 yarn-resource-cost/yarn_resource_cost.py \
  --adapter on-prem \
  --event-log-root /archive/spark-events \
  --yarn-log-root /archive/yarn-daemon-logs.tar.gz \
  --node-class-map node-classes.json \
  --pricing catalog \
  --price-catalog internal-rates.json \
  --output-csv application-cost.csv
```

Compare a baseline with one or more test reruns. Later test roots replace earlier
ones with the same comparison key:

```bash
python3 yarn-resource-cost/yarn_resource_cost.py \
  --adapter emr \
  --event-log-root s3://example-bucket/baseline/events/ \
  --test-event-log-root s3://example-bucket/test/events/ \
  --comparison-key regex \
  --comparison-key-regex 'job-(?P<key>[0-9]+)' \
  --pricing live \
  --sort-by cost-factor
```

For non-EMR comparisons, pair every `--test-event-log-root` with a
`--test-yarn-log-root` in the same order.

## Input schemas

Node classes are adapter-stable worker shapes, not hostnames:

```json
{
  "schema_version": 1,
  "nodes": {
    "worker-01.example.net": "onprem:gpu-a10-16c-128g"
  },
  "default_node_class": "onprem:cpu-32c-256g"
}
```

Pricing is deliberately separate from accounting:

```json
{
  "schema_version": 1,
  "currency": "USD",
  "effective_at": "2026-08-01T00:00:00Z",
  "source": "approved internal rate card",
  "rates": [
    {"node_class": "onprem:cpu-32c-256g", "hourly_rate": 4.25}
  ]
}
```

JSON output uses `schema_version: 1` and retains input roots, discovery source,
calculator evidence, node capacities, resource expressions, completeness,
warnings, pricing provenance, applications, and run summaries.
The `nodes` object contains RM-registered nodes and nodes referenced by
containers of the selected applications; unrelated daemon-log directory names
are omitted.

## Reproducible experiment capture

Archive these together for every benchmark run:

1. All Spark event-log segments through `SparkListenerApplicationEnd`.
2. All rolled ResourceManager and NodeManager daemon logs for the cluster.
3. `yarn-site.xml`, `resource-types.xml`, and the active
   `capacity-scheduler.xml` or `fair-scheduler.xml`.
4. Provider cluster descriptions and host-to-node-class mappings.
5. A frozen price catalog when results must be reproducible later.
6. A small manifest linking each event-log root to its YARN log root and node
   map. Never rely on a live cluster remaining available.

## Compatibility command

`calculate_yarn_job_cost.py` preserves the original EMR-oriented command and
output columns for existing integrations. New integrations should use
`yarn_resource_cost.py` and its provider-neutral versioned JSON output.

## License and contribution

The tool is licensed under Apache License 2.0 as part of this repository. See
the repository `LICENSE` and `CONTRIBUTING.md`. Generated standalone bundles
include both documents and a checksum manifest.
