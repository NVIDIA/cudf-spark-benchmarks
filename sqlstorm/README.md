# SQLStorm NDS and NDS-H extension queries

This corpus adds SQLStorm queries to the correctness work tracked in
[NVIDIA/cudf-spark-benchmarks#296](https://github.com/NVIDIA/cudf-spark-benchmarks/issues/296).
NDS and NDS-H map to SQLStorm's `tpcds` and `tpch` collections at
[revision b3bb0b9](https://github.com/SQL-Storm/SQLStorm/tree/b3bb0b96794a6afe9bb8f3ff2b243562b779c40d).
Query filenames preserve SQLStorm's source IDs, including five-digit IDs.
Always identify a query by both dataset and ID; `nds/107` and `nds-h/107`
are separate queries.

## Included queries

| SQL variant | NDS | NDS-H | Total |
|---|---:|---:|---:|
| Original SQL | 11,401 | 11,998 | 23,399 |
| Spark-adapted SQL | 1,868 | 996 | 2,864 |
| Total | 13,269 | 12,994 | 26,263 |

The original collection includes the 23,397 queries that completed the first
GPU sweep, plus NDS 2093 and 3109, which completed the later saved-reference
smoke job. The adapted collection retains the 2,864-query set after excluding
600 CPU query failures. Their IDs, original hashes and error classes remain in
`excluded-cpu-failures.csv`; their SQL is excluded from the checked-in corpus.
The upstream denominator remains 15,242 NDS and 17,036 NDS-H queries.

`catalog.jsonl` records each query's source path/hash, executable hash, variant,
exact adaptation edits, review flags, execution/comparison status and related
issues. `catalog.json` records the pinned source, license, counts and campaign
environments. SQL files keep their recorded bytes and line endings.

| Suite | NDS | NDS-H | Meaning |
|---|---:|---:|---|
| `smoke` | 12 | 12 | Previously exercised saved-reference smoke selection |
| `extended` | 13,264 | 12,976 | GPU execution completed in a recorded campaign |
| `pending` | 5 | 18 | GPU timeout or known execution failure; explicit opt-in |

Smoke is a subset of extended. Extended and pending partition the corpus;
their ID lists are under `suites/`. A suite is a selection, not an instruction
to submit every query at once or enable a recurring job. Use bounded batches
on shared CI resources. This PR supplies query content and metadata; the
prototype runner and existing internal Jenkins jobs remain separate.

## Validation status

Execution completion is separate from correctness. The first GPU sweep used
Spark 3.5.7 without a complete CPU oracle. The adapted campaign used Spark
4.0.4 and attempted CPU/GPU comparisons on SF1. The metadata preserves exact
matches, strict differences, ordering reviews, unstable CPU references and
unvalidated results. The original queries have not all been rerun on Spark
4.0.4. The historical smoke job matched all 12 queries in each dataset against
its saved CPU reference; that result does not establish full-corpus coverage.

CPU timeouts remain pending reference work. GPU execution completion alone
does not establish a usable CPU baseline. Generate the reference with an
explicit manual CPU run, save complete typed results and timings, then use
GPU-only campaigns against that chosen reference. Missing references,
capture limits, errors and timeouts cannot count as correctness passes.

Known defects remain visible in query metadata and are not converted to
passing results or tolerance-based comparisons:

- [ROUND differences #1573](https://github.com/NVIDIA/cudf-spark/issues/1573).
- [GPU ordering #9573](https://github.com/NVIDIA/cudf-spark/issues/9573).
- [Interval/AQE execution failure #16643](https://github.com/NVIDIA/cudf-spark/issues/16643).
- [NULL scalar aggregate/COALESCE values #16656](https://github.com/NVIDIA/cudf-spark/issues/16656).

Two isolated GPU timeouts link to
[#7529](https://github.com/NVIDIA/cudf-spark/issues/7529) as related evidence;
their root-cause relationship to that issue is unproven. Unordered aggregates,
window ties and pagination retain review metadata. Their presence, or a
changing CPU result, does not by itself prove the GPU output valid.

Recorded edits remove redundant nonrecursive `RECURSIVE`, translate literal
FETCH/OFFSET syntax, or replace unsized VARCHAR/TEXT casts. Reproduction of
those edits proves byte provenance, not general SQL semantic equivalence.
There is no GPU operator coverage gate. SF1 observations do not establish
3 TB runtime, speedup or equivalence to published TPC Benchmark Results.

## Use and verify the checked-in SQL

No SQLStorm checkout, Spark installation or Python package dependency is needed
to inspect the corpus and validate its integrity:

```bash
python3 -m unittest discover -s sqlstorm/tests -p 'test*.py' -v
python3 -m sqlstorm.catalog validate
```

For example, obtain the selected SQL after registering the matching NDS tables:

```python
from sqlstorm.catalog import ROOT, records, suite

dataset = "nds"
selected = set(suite(dataset, "smoke")["selected"])
queries = {
    entry["id"]: (ROOT / entry["path"]).read_text(encoding="utf-8")
    for entry in records()
    if entry["dataset"] == dataset and entry["id"] in selected
}
# Pass queries to the chosen Spark execution/result-recording harness.
```

The validator checks every SQL hash, duplicate IDs, exact dataset paths,
suite partitions, CPU exclusions and the retained MIT license. The dedicated
GitHub workflow runs it without a GPU. It does not execute the SQL.

To independently reproduce every query from upstream, check out the pinned
SQLStorm revision and restore into a new directory:

```bash
git clone https://github.com/SQL-Storm/SQLStorm.git /path/to/SQLStorm
git -C /path/to/SQLStorm checkout b3bb0b96794a6afe9bb8f3ff2b243562b779c40d
python3 -m sqlstorm.catalog restore --upstream /path/to/SQLStorm \
  --output /new/restored-corpus
```

Restoration checks the revision, original source bytes and license, applies
only the recorded source spans, and requires each executable hash to match.
Original SQL is copied byte-for-byte. Adapted SQL uses the recorded Python
text-reading newline normalization before applying edits.

## License

The SQL files under `queries/` retain SQLStorm's **MIT license**, including
`Copyright (c) 2025, TUM`, in [queries/LICENSE](queries/LICENSE).
They are not relabeled as NVIDIA-authored Apache-2.0 SQL. New catalog utilities
and checks use the repository's Apache-2.0 license. The repository NOTICE
identifies this third-party component. Its exact SQL bytes are excluded only
from the corporate copyright-header assertion; the corpus check verifies their
retained license and content hashes.
