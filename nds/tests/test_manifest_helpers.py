# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test manifest parsing and actual driver plumbing without starting Spark."""

import contextlib
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import sys
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power as driver


class ManifestHelpersTest(unittest.TestCase):
    def session(self, content, exists=True):
        session = Mock()
        filesystem = session._jvm.org.apache.hadoop.fs.Path.return_value.getFileSystem.return_value
        filesystem.exists.return_value = exists
        scanner = SimpleNamespace(useDelimiter=lambda value: None, hasNext=lambda: True,
                                  next=lambda: content, closed=False)
        scanner.close = lambda: setattr(scanner, 'closed', True)
        session._jvm.java.util.Scanner.return_value = scanner
        return session, scanner

    def test_missing_marker_and_manifest_table_selection(self):
        tables = {'date_dim': {'date_partition_column': None},
                  'orders': {'date_partition_column': 'order_day'},
                  'customers': {'date_partition_column': None}}
        session, scanner = self.session(json.dumps({'tables': tables}))
        self.assertEqual(driver._manifest_tables(session, '/data', 'parquet'),
                         (['date_dim', 'orders', 'customers'], {'orders': 'order_day'}))
        self.assertTrue(scanner.closed)
        session, scanner = self.session('', exists=False)
        self.assertIsNone(driver._manifest_tables(session, '/data', 'csv'))
        self.assertFalse(scanner.closed)

    def test_no_cutoff_accepts_tables_without_date_metadata_or_date_dim(self):
        session, scanner = self.session(json.dumps({'tables': {'orders': {}, 'customers': {}}}))
        self.assertEqual(driver._manifest_tables(session, '/data', 'parquet'),
                         (['orders', 'customers'], {}))
        self.assertTrue(scanner.closed)

    def test_errors_preserve_scanner_cleanup(self):
        for content, message in (('{', 'Expecting'),
                                 ('{"tables": {}}', 'nonempty tables object'),
                                 ('{"tables": []}', 'nonempty tables object'),
                                 ('{"tables": {"orders": null}}', 'metadata must be an object'),
                                 ('{"tables": {"orders": {"date_partition_column": ""}}}',
                                  'nonempty string or null'),
                                 ('{"tables": {"orders": {"date_partition_column": 7}}}',
                                  'nonempty string or null')):
            with self.subTest(content=content):
                session, scanner = self.session(content)
                with self.assertRaisesRegex(ValueError, message):
                    driver._manifest_tables(session, '/data', 'parquet')
                self.assertTrue(scanner.closed)
        session, scanner = self.session('{}')
        with self.assertRaisesRegex(ValueError, 'requires Parquet'):
            driver._manifest_tables(session, '/data', 'orc')
        self.assertFalse(scanner.closed)

    def test_driver_uses_same_tables_for_loading_and_statistics(self):
        for manifest in (None, (['date_dim', 'orders'], {'orders': 'order_day'})):
            with self.subTest(manifest=manifest), tempfile.TemporaryDirectory() as directory:
                session = Mock()
                session.conf.get.return_value = 'app'
                builder = Mock()
                builder.appName.return_value.getOrCreate.return_value = session
                loaded = {}
                def setup(*args):
                    loaded['tables'], loaded['dates'] = list(args[8]), args[9]
                    return args[4]
                def analyze(spark, mode, tables, folder):
                    loaded['analyzed'] = list(tables)
                    return {'duration_ms': 0}
                with patch.object(driver.SparkSession, 'builder', builder), \
                        patch.object(driver, '_manifest_tables', return_value=manifest), \
                        patch.object(driver, 'setup_tables', side_effect=setup), \
                        patch.object(driver, 'analyze_catalog', side_effect=analyze), \
                        patch.object(driver, 'Profiler'), patch.object(driver, 'clearQueryName'), \
                        contextlib.redirect_stdout(io.StringIO()):
                    driver.run_query_stream(
                        '/data', None, {}, str(Path(directory) / 'times.csv'),
                        None, None, None, 0, 1, None, analyze='all_columns')
                expected = list(driver.get_schemas(False)) if manifest is None else manifest[0]
                self.assertEqual(loaded['tables'], expected)
                self.assertEqual(loaded['analyzed'], expected)
                self.assertEqual(loaded['dates'], driver.DATE_PARTITION_COLUMNS
                                 if manifest is None else manifest[1])


if __name__ == '__main__':
    unittest.main()
