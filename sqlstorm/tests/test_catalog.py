# Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
"""Check corpus corruption, namespace collisions, exclusions and byte restoration."""
import csv
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from sqlstorm.catalog import restore, sha256, validate


class CatalogTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "catalog"
        self.upstream = Path(self.temporary.name) / "upstream"
        self.root.mkdir()
        self.upstream.mkdir()
        license_bytes = b"MIT License\nCopyright (c) 2025, TUM\n"
        (self.upstream / "LICENSE").write_bytes(license_bytes)
        self.entries = []
        for dataset, collection in (("nds", "tpcds"), ("nds-h", "tpch")):
            source = f"v1.0/{collection}/queries/1.sql"
            data = f"SELECT '{dataset}; λ' AS label;\r\n".encode()
            entry = self.add_query(dataset, "1", source, data, data, [])
            entry["smoke_validation"] = {
                "campaign": "saved_reference_smoke_spark404_sf1", "comparison": "match"}
            self.entries.append(entry)
        source = "v1.0/tpcds/queries/2.sql"
        original = b"SELECT 2 FETCH FIRST 1 ROWS ONLY;\r\n"
        # The recorded source span excludes the terminal semicolon.
        edit = {"start": 9, "end": original.decode().index(";"),
                "replacement": "LIMIT 1", "rule": "literal_fetch"}
        self.entries.append(self.add_query(
            "nds", "2", source, original, b"SELECT 2 LIMIT 1;\n", [edit], pending=True))
        (self.root / "queries" / "LICENSE").write_bytes(license_bytes)
        (self.root / "suites").mkdir()
        for dataset in ("nds", "nds-h"):
            for name, selected in (("extended", ["1"]), ("smoke", ["1"]),
                                   ("pending", ["2"] if dataset == "nds" else [])):
                self.write_suite(dataset, name, selected)
        self.metadata = {
            "upstream_revision": "a" * 40,
            "included_by_dataset": {"nds": 2, "nds-h": 1},
            "excluded_by_dataset": {"nds": 1},
            "suites": {"nds": {"extended": 1, "pending": 1},
                       "nds-h": {"extended": 1, "pending": 0}},
        }
        self.write_exclusions([{"dataset": "nds", "id": "99"}])
        self.refresh_metadata()

    def add_query(self, dataset, query_id, source_path, original, data, edits, pending=False):
        target = self.upstream / source_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(original)
        path = f"queries/{dataset}/{query_id}.sql"
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        return {"dataset": dataset, "id": query_id, "source_path": source_path,
                "source_sha256": sha256(original), "path": path, "sql_sha256": sha256(data),
                "variant": "spark_adapted" if edits else "original", "edits": edits,
                "suite": "pending" if pending else "extended",
                "validation": {"gpu_status": "timeout" if pending else "ok", "cpu_status": "ok"}}

    def write_suite(self, dataset, name, selected):
        (self.root / "suites" / f"{dataset}-{name}.json").write_text(
            json.dumps({"dataset": dataset, "selected": selected}))

    def write_exclusions(self, rows):
        with (self.root / "excluded-cpu-failures.csv").open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=["dataset", "id"])
            writer.writeheader()
            writer.writerows(rows)

    def refresh_metadata(self):
        (self.root / "catalog.jsonl").write_text(
            "".join(json.dumps(entry) + "\n" for entry in self.entries))
        for field, path in (("catalog_sha256", "catalog.jsonl"),
                            ("excluded_sha256", "excluded-cpu-failures.csv"),
                            ("license_sha256", "queries/LICENSE")):
            self.metadata[field] = sha256((self.root / path).read_bytes())
        (self.root / "catalog.json").write_text(json.dumps(self.metadata))

    def init_upstream(self):
        def git(*args):
            return subprocess.check_output(
                ["git", "-C", str(self.upstream), *args], stderr=subprocess.STDOUT, text=True)
        git("init", "-q")
        git("add", ".")
        git("-c", "user.name=Catalog Test", "-c", "user.email=catalog@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "Fixture")
        self.metadata["upstream_revision"] = git("rev-parse", "HEAD").strip()
        self.refresh_metadata()

    def test_dataset_qualified_ids_and_pending_partition(self):
        result = validate(self.root)
        self.assertEqual(result["queries"], 3)
        self.assertEqual(result["datasets"], {"nds": 2, "nds-h": 1})

    def test_changed_sql_is_rejected(self):
        (self.root / "queries/nds/1.sql").write_text("SELECT 'different';")
        with self.assertRaisesRegex(ValueError, "SQL content mismatch"):
            validate(self.root)

    def test_missing_license_is_not_replaced_with_repository_license(self):
        (self.root / "queries/LICENSE").write_text("Apache-2.0")
        with self.assertRaisesRegex(ValueError, "MIT license changed"):
            validate(self.root)

    def test_duplicate_query_in_same_dataset_is_rejected(self):
        self.entries.append(dict(self.entries[0]))
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "Duplicate dataset/query ID"):
            validate(self.root)

    def test_path_escape_is_rejected(self):
        self.entries[0]["path"] = "../outside.sql"
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "Unexpected query path"):
            validate(self.root)

    def test_cpu_failure_cannot_be_imported(self):
        self.entries[0]["validation"]["cpu_status"] = "error"
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "CPU failure cannot"):
            validate(self.root)

    def test_unfinished_gpu_cannot_enter_extended_suite(self):
        self.entries[-1]["suite"] = "extended"
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "Unfinished GPU execution"):
            validate(self.root)

    def test_duplicate_suite_selection_is_rejected(self):
        self.write_suite("nds", "extended", ["1", "1"])
        with self.assertRaisesRegex(ValueError, "Invalid suite selection"):
            validate(self.root)

    def test_empty_smoke_selection_is_rejected(self):
        for dataset in ("nds", "nds-h"):
            with self.subTest(dataset=dataset):
                self.write_suite(dataset, "smoke", [])
                with self.assertRaisesRegex(ValueError, "Smoke selection"):
                    validate(self.root)
                self.write_suite(dataset, "smoke", ["1"])

    def test_unvalidated_smoke_substitution_is_rejected(self):
        data = b"SELECT 3;\n"
        self.entries.append(self.add_query(
            "nds", "3", "v1.0/tpcds/queries/3.sql", data, data, []))
        self.metadata["included_by_dataset"]["nds"] += 1
        self.metadata["suites"]["nds"]["extended"] += 1
        self.write_suite("nds", "extended", ["1", "3"])
        self.write_suite("nds", "smoke", ["3"])
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "Smoke selection"):
            validate(self.root)

    def test_excluded_cpu_query_cannot_be_imported(self):
        self.write_exclusions([{"dataset": "nds", "id": "1"}])
        self.refresh_metadata()
        with self.assertRaisesRegex(ValueError, "imported CPU exclusion"):
            validate(self.root)

    def test_unlisted_sql_is_rejected(self):
        (self.root / "queries/nds/99.sql").write_text("SELECT 99;")
        with self.assertRaisesRegex(ValueError, "Unlisted or missing SQL"):
            validate(self.root)

    def test_restore_preserves_crlf_unicode_and_changes_only_recorded_spans(self):
        self.init_upstream()
        output = Path(self.temporary.name) / "restored"
        self.assertEqual(restore(self.upstream, output, self.root)["queries"], 3)
        for entry in self.entries:
            self.assertEqual((output / entry["path"]).read_bytes(),
                             (self.root / entry["path"]).read_bytes())

    def test_restore_rejects_modified_upstream_source(self):
        self.init_upstream()
        (self.upstream / self.entries[0]["source_path"]).write_text("SELECT 999;")
        with self.assertRaisesRegex(ValueError, "Upstream SQL differs"):
            restore(self.upstream, Path(self.temporary.name) / "restored", self.root)

    def test_restore_refuses_existing_output(self):
        self.init_upstream()
        with self.assertRaisesRegex(ValueError, "new directory"):
            restore(self.upstream, self.root, self.root)


if __name__ == "__main__":
    unittest.main()
