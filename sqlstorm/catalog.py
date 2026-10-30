# Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
"""Validate the checked-in corpus or reproduce its SQL from pinned upstream bytes.

These operations do not execute Spark or establish result correctness.
"""
import argparse
import collections
import csv
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
DATASETS = {"nds": "tpcds", "nds-h": "tpch"}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def records(root=ROOT):
    with (Path(root) / "catalog.jsonl").open(encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def suite(dataset, name="extended", root=ROOT):
    if dataset not in DATASETS or name not in ("smoke", "extended", "pending"):
        raise ValueError("Unknown dataset or suite")
    return json.loads((Path(root) / "suites" / f"{dataset}-{name}.json").read_text())


def validate(root=ROOT):
    root = Path(root)
    metadata = json.loads((root / "catalog.json").read_text())
    if sha256((root / "queries" / "LICENSE").read_bytes()) != metadata["license_sha256"]:
        raise ValueError("Upstream MIT license changed")
    if sha256((root / "catalog.jsonl").read_bytes()) != metadata["catalog_sha256"]:
        raise ValueError("Catalog digest mismatch")
    if sha256((root / "excluded-cpu-failures.csv").read_bytes()) != metadata["excluded_sha256"]:
        raise ValueError("CPU exclusion digest mismatch")
    entries = records(root)
    keys, paths, observed = set(), set(), collections.Counter()
    by_dataset = {dataset: {} for dataset in DATASETS}
    for entry in entries:
        dataset, query_id = entry["dataset"], entry["id"]
        if dataset not in DATASETS or not query_id.isascii() or not query_id.isdecimal():
            raise ValueError("Invalid dataset/query ID")
        key = dataset, query_id
        if key in keys:
            raise ValueError("Duplicate dataset/query ID")
        keys.add(key)
        relative = f"queries/{dataset}/{query_id}.sql"
        source = f"v1.0/{DATASETS[dataset]}/queries/{query_id}.sql"
        if entry["path"] != relative or entry["source_path"] != source:
            raise ValueError("Unexpected query path")
        path = root / relative
        if path.is_symlink() or sha256(path.read_bytes()) != entry["sql_sha256"]:
            raise ValueError("SQL content mismatch: " + relative)
        if entry["variant"] == "original":
            if entry["source_sha256"] != entry["sql_sha256"] or entry["edits"]:
                raise ValueError("Original SQL has adaptation edits")
        elif entry["variant"] != "spark_adapted" or not entry["edits"]:
            raise ValueError("Missing adaptation provenance")
        if entry["validation"]["cpu_status"] in ("error", "crash"):
            raise ValueError("CPU failure cannot be included in the corpus")
        expected_suite = "extended" if entry["validation"]["gpu_status"] == "ok" else "pending"
        if entry["suite"] != expected_suite:
            raise ValueError("Unfinished GPU execution included in extended suite")
        paths.add(path)
        by_dataset[dataset][query_id] = entry
        observed[dataset] += 1
    actual_paths = set((root / "queries").glob("*/*.sql"))
    if paths != actual_paths:
        raise ValueError("Unlisted or missing SQL files")
    if dict(observed) != metadata["included_by_dataset"]:
        raise ValueError("Catalog counts disagree")
    for dataset in DATASETS:
        selections = {}
        for name in ("smoke", "extended", "pending"):
            value = suite(dataset, name, root)
            selected = value["selected"]
            if value["dataset"] != dataset or len(set(selected)) != len(selected):
                raise ValueError("Invalid suite selection")
            if not set(selected) <= by_dataset[dataset].keys():
                raise ValueError("Suite contains an unlisted query")
            selections[name] = set(selected)
        if selections["extended"] & selections["pending"]:
            raise ValueError("Overlapping extended/pending suites")
        if selections["extended"] | selections["pending"] != by_dataset[dataset].keys():
            raise ValueError("Suites do not partition the dataset")
        if not selections["smoke"] <= selections["extended"]:
            raise ValueError("Smoke query has not completed GPU execution")
        expected_smoke = {
            query_id for query_id, entry in by_dataset[dataset].items()
            if entry.get("smoke_validation", {}).get("comparison") == "match"}
        if not expected_smoke or selections["smoke"] != expected_smoke:
            raise ValueError("Smoke selection does not match saved-reference validation")
        for name in ("extended", "pending"):
            if any(by_dataset[dataset][query_id]["suite"] != name
                   for query_id in selections[name]):
                raise ValueError("Suite disagrees with query execution status")
            expected = metadata["suites"][dataset][name]
            if len(selections[name]) != expected:
                raise ValueError("Suite count mismatch")
    with (root / "excluded-cpu-failures.csv").open(newline="", encoding="utf-8") as handle:
        excluded = list(csv.DictReader(handle))
    excluded_keys = [(entry["dataset"], entry["id"]) for entry in excluded]
    if len(set(excluded_keys)) != len(excluded) or set(excluded_keys) & keys:
        raise ValueError("Duplicate or imported CPU exclusion")
    excluded_counts = dict(collections.Counter(entry["dataset"] for entry in excluded))
    if excluded_counts != metadata["excluded_by_dataset"]:
        raise ValueError("CPU exclusion count mismatch")
    return {"queries": len(entries), "datasets": dict(observed),
            "excluded_cpu_failures": len(excluded), "status": "catalog_integrity_validated"}


def restore(upstream, output, root=ROOT):
    """Apply the recorded edits without changing other source text."""
    validate(root)
    upstream, output = Path(upstream), Path(output)
    metadata = json.loads((Path(root) / "catalog.json").read_text())
    revision = subprocess.check_output(
        ["git", "-C", str(upstream), "rev-parse", "HEAD"], text=True).strip()
    if revision != metadata["upstream_revision"]:
        raise ValueError("Unexpected upstream revision")
    if sha256((upstream / "LICENSE").read_bytes()) != metadata["license_sha256"]:
        raise ValueError("Upstream license differs")
    if output.exists():
        raise ValueError("Restore output must be a new directory")
    output.mkdir(parents=True)
    for entry in records(root):
        source = upstream / entry["source_path"]
        data = source.read_bytes()
        if sha256(data) != entry["source_sha256"]:
            raise ValueError("Upstream SQL differs: " + entry["source_path"])
        if entry["edits"]:
            text = source.read_text(encoding="utf-8")
            edits = sorted(entry["edits"], key=lambda edit: edit["start"])
            previous_end = 0
            for edit in edits:
                if not 0 <= previous_end <= edit["start"] < edit["end"] <= len(text):
                    raise ValueError("Invalid or overlapping source edits")
                previous_end = edit["end"]
            for edit in reversed(edits):
                text = text[:edit["start"]] + edit["replacement"] + text[edit["end"]:]
            data = text.encode("utf-8")
        if sha256(data) != entry["sql_sha256"]:
            raise ValueError("Restored SQL differs: " + entry["path"])
        target = output / entry["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    (output / "queries" / "LICENSE").write_bytes((upstream / "LICENSE").read_bytes())
    return {"queries": len(records(root)), "status": "restored_exact_sql_bytes"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate")
    rebuild = commands.add_parser("restore")
    rebuild.add_argument("--upstream", type=Path, required=True)
    rebuild.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = validate() if args.command == "validate" else restore(args.upstream, args.output)
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
