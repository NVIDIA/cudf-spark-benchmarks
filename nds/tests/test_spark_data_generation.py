# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock

from pyspark import SparkFiles

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import nds_gen_data_spark as data_gen


FAKE_DSDGEN = """#!/usr/bin/env python3
import os
from pathlib import Path
import sys

args = dict(zip(sys.argv[1::2], sys.argv[2::2]))
output = Path(args["-dir"])
child, parallel = args["-child"], args["-parallel"]
if os.environ.get("DSDGEN_INVOCATIONS"):
    with open(os.environ["DSDGEN_INVOCATIONS"], "a") as log:
        log.write(child + "\\n")
if os.environ.get("DSDGEN_FAIL"):
    (output / "unfinished.dat").write_text("partial")
    sys.exit("injected dsdgen failure")
(output / f"customer_{child}_{parallel}.dat").write_text(child + "|value|\\n\\n")
if "-update" in args:
    for table in ("delete", "inventory_delete"):
        (output / f"{table}_{args['-update']}.dat").write_text("same-delete-row|\\n")
(output / "unrelated.txt").write_text("ignored")
"""


class SparkDataGenerationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        tools = self.root / "dsdgen" / "tools"
        tools.mkdir(parents=True)
        (tools / "dsdgen").write_text(FAKE_DSDGEN)
        (tools / "dsdgen").chmod(0o755)
        self.root_patch = mock.patch.object(
            SparkFiles, "getRootDirectory", return_value=str(self.root))
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)

    def generated(self, children, update=1):
        return [row for child in children
                for row in data_gen.run_dsdgen_and_read(child, 1, 3, update)]

    def test_update_delete_datasets_are_emitted_once(self):
        rows = self.generated([1, 2, 3])
        for table in ("delete", "inventory_delete"):
            self.assertEqual([value for name, value in rows if name == table], ["same-delete-row|"])
        self.assertEqual([value for name, value in rows if name == "customer"],
                         ["1|value|", "2|value|", "3|value|"])

    def test_later_child_range_does_not_repeat_delete_datasets(self):
        self.assertEqual(self.generated([2, 3]),
                         [("customer", "2|value|"), ("customer", "3|value|")])

    def test_first_child_range_keeps_delete_datasets(self):
        self.assertCountEqual(self.generated([1]),
                              [("customer", "1|value|"), ("delete", "same-delete-row|"),
                               ("inventory_delete", "same-delete-row|")])

    def test_base_data_is_unchanged(self):
        self.assertEqual(self.generated([1, 2], update=None),
                         [("customer", "1|value|"), ("customer", "2|value|")])

    def test_failed_generation_cleans_partial_output(self):
        paths = []
        real_mkdtemp = tempfile.mkdtemp

        def tracked_mkdtemp(*args, **kwargs):
            path = real_mkdtemp(*args, **kwargs)
            paths.append(Path(path))
            return path

        with mock.patch.dict(os.environ, {"DSDGEN_FAIL": "1"}):
            with mock.patch.object(data_gen.tempfile, "mkdtemp", side_effect=tracked_mkdtemp):
                with self.assertRaisesRegex(RuntimeError, "injected dsdgen failure"):
                    list(data_gen.run_dsdgen_and_read(1, 1, 3, 1))
        self.assertEqual(len(paths), 1)
        self.assertFalse(paths[0].exists())

    def test_early_iterator_close_cleans_output(self):
        paths = []
        real_mkdtemp = tempfile.mkdtemp

        def tracked_mkdtemp(*args, **kwargs):
            path = real_mkdtemp(*args, **kwargs)
            paths.append(Path(path))
            return path

        with mock.patch.object(data_gen.tempfile, "mkdtemp", side_effect=tracked_mkdtemp):
            rows = data_gen.run_dsdgen_and_read(1, 1, 3, 1)
            self.assertEqual(next(rows), ("customer", "1|value|"))
            rows.close()
        self.assertEqual(len(paths), 1)
        self.assertFalse(paths[0].exists())

    def test_local_spark_writes_once_per_child_without_schema_inference(self):
        archive = self.root / "dsdgen.tar.gz"
        with tarfile.open(archive, "w:gz") as packed:
            packed.add(self.root / "dsdgen" / "tools", arcname="tools")
        invocations = self.root / "invocations.txt"
        output = self.root / "output"
        submit_args = f"--master local[2] --archives {archive}#dsdgen pyspark-shell"
        env = dict(os.environ, DSDGEN_INVOCATIONS=str(invocations), SPARK_LOCAL_IP="127.0.0.1",
                   PYSPARK_PYTHON=sys.executable, PYSPARK_DRIVER_PYTHON=sys.executable,
                   PYSPARK_SUBMIT_ARGS=submit_args)
        result = subprocess.run(
            [sys.executable, str(Path(data_gen.__file__).resolve()),
             "1", "2", str(output), "--update", "1"],
            env=env, capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertCountEqual(invocations.read_text().splitlines(), ["1", "2"])
        for table in ("delete", "inventory_delete"):
            rows = [line for part in (output / table).glob("part-*")
                    for line in part.read_text().splitlines()]
            self.assertEqual(rows, ["same-delete-row|"])
        self.assertIn("=== Data generation complete:", result.stdout)


if __name__ == "__main__":
    unittest.main()
