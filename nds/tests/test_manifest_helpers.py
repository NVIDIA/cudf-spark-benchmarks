# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test explicit manifest parsing and driver selection without starting Spark."""

import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import sys
import subprocess
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

    def test_hadoop_uri_selects_the_explicit_manifest_and_closes_its_reader(self):
        tables = {'date_dim': {}, 'orders': {'date_partition_column': 'order_day'},
                  'customers': {}}
        session, scanner = self.session(json.dumps({'tables': tables}))
        path = session._jvm.org.apache.hadoop.fs.Path.return_value
        selected = []
        def hadoop_path(uri):
            selected.append(uri)
            return path
        session._jvm.org.apache.hadoop.fs.Path.side_effect = hadoop_path
        uri = 's3a://datasets/metadata/custom.json'
        self.assertEqual(driver._manifest_tables(session, uri),
                         tables)
        self.assertEqual(selected, [uri])
        self.assertTrue(scanner.closed)

    def test_local_manifest_needs_no_date_metadata_or_hadoop_filesystem(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / 'custom.json'
            manifest.write_text(json.dumps({'tables': {'orders': {}, 'customers': {}}}))
            self.assertEqual(driver._manifest_tables(None, str(manifest)),
                             {'orders': {}, 'customers': {}})
            manifest.unlink()
            with self.assertRaises(FileNotFoundError):
                driver._manifest_tables(None, str(manifest))

    def test_missing_hadoop_manifest_is_an_error(self):
        session, scanner = self.session('', exists=False)
        with self.assertRaisesRegex(ValueError, 'Dataset manifest does not exist'):
            driver._manifest_tables(session, 'hdfs:///metadata/missing.json')
        self.assertFalse(scanner.closed)

    def test_invalid_manifest_reports_metadata_errors(self):
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
                    driver._manifest_tables(session, 'hdfs:///custom.json')
                self.assertTrue(scanner.closed)

    def test_manifest_validates_names_fields_and_ordered_partition_metadata(self):
        invalid = [
            ({'': {}}, 'table names'), ({'..': {}}, 'table names'),
            ({'my-table': {}}, 'table names'), ({'123': {}}, 'table names'),
            ({'Foo': {}, 'foo': {}}, 'Duplicate manifest'),
            ({'orders': {'date_partition_columns': 'day'}}, 'Unknown manifest table fields'),
            ({'orders': {'partition_columns': 'day'}}, 'list of nonempty strings'),
            ({'orders': {'partition_columns': None}}, 'list of nonempty strings'),
            ({'orders': {'partition_columns': ['']}}, 'list of nonempty strings'),
            ({'orders': {'partition_columns': ['day', 'DAY']}}, 'Duplicate partition_columns'),
            ({'orders': {'partition_columns': [], 'date_partition_column': 'day'}},
             'must occur in partition_columns'),
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'manifest.json'
            for tables, error in invalid:
                path.write_text(json.dumps({'tables': tables}))
                with self.subTest(tables=tables), self.assertRaisesRegex(ValueError, error):
                    driver._manifest_tables(None, str(path))
            valid = {'Foo': {'partition_columns': ['region', 'day'], 'date_partition_column': 'day'},
                     'other': {'partition_columns': []}}
            path.write_text(json.dumps({'tables': valid, 'parameters': {'seed': 7}}))
            session = SimpleNamespace(conf=SimpleNamespace(get=lambda *args: 'true'))
            self.assertEqual(driver._manifest_tables(session, str(path)), valid)
            for tables in ({'Foo': {}, 'foo': {}},
                           {'orders': {'partition_columns': ['day', 'DAY']}}):
                path.write_text(json.dumps({'tables': tables}))
                with self.subTest(case_sensitive=True, tables=tables):
                    with self.assertRaisesRegex(ValueError, 'Duplicate'):
                        driver._manifest_tables(session, str(path))

    def test_colon_filename_is_local_and_single_slash_file_uri_remains_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'workload:v2.json'
            path.write_text(json.dumps({'tables': {'orders': {}}}))
            # Use the relative spelling that urlparse would otherwise treat as a scheme.
            previous = os.getcwd()
            try:
                os.chdir(directory)
                self.assertEqual(driver._manifest_tables(None, 'workload:v2.json'), {'orders': {}})
            finally:
                os.chdir(previous)
            session, _ = self.session(json.dumps({'tables': {'orders': {}}}))
            self.assertEqual(driver._manifest_tables(session, 'file:/metadata/custom.json'),
                             {'orders': {}})

    def test_builtin_nds_tables_describe_their_single_date_partition(self):
        tables = driver._dataset_tables('/data', 'parquet', False)
        self.assertEqual({name: table['partition_columns'] for name, table in tables.items()
                          if table['partition_columns'] is not None},
                         {name: [column] for name, column in driver.DATE_PARTITION_COLUMNS.items()})

    def test_explicit_manifest_requires_classic_file_backed_parquet(self):
        for options, message in (({'hive_external': True}, 'external Hive tables'),
                                 ({'spark_connect': 'sc://localhost'}, 'Spark Connect')):
            with self.subTest(options=options):
                with self.assertRaisesRegex(ValueError, message):
                    driver.run_query_stream('/data', None, {}, '/tmp/times.csv',
                                            None, None, None, 0, 1, None,
                                            dataset_manifest='/custom.json', **options)

    def test_manifest_rejects_explicit_input_format_including_parquet(self):
        for input_format in ('parquet', 'orc', 'avro', 'csv', 'json', 'iceberg', 'delta'):
            with self.subTest(input_format=input_format):
                with self.assertRaisesRegex(ValueError, 'cannot be combined'):
                    driver.run_query_stream('/data', None, {}, '/tmp/times.csv',
                                            None, None, None, 0, 1, None,
                                            input_format=input_format,
                                            dataset_manifest='/custom.json')

    def test_cli_rejects_both_dataset_options_in_either_order_before_reading_inputs(self):
        for input_format in ('parquet', 'json'):
            for manifest_first in (False, True):
                with self.subTest(input_format=input_format, manifest_first=manifest_first):
                    options = [['--input_format', input_format],
                               ['--dataset_manifest', '/missing-manifest.json']]
                    if manifest_first:
                        options.reverse()
                    result = subprocess.run(
                        [sys.executable, str(Path(driver.__file__)), '/missing-data',
                         '/missing-queries.sql', '/unused-times.csv',
                         *[value for pair in options for value in pair]],
                        capture_output=True, text=True)
                    self.assertEqual(result.returncode, 2)
                    self.assertIn('--input_format', result.stderr)
                    self.assertIn('--dataset_manifest', result.stderr)
                    self.assertIn('not allowed with argument', result.stderr)

    def test_omission_ignores_colocated_manifest_and_preserves_nds_tables(self):
        self.assert_driver_table_selection(explicit=False)

    def test_explicit_manifest_uses_same_tables_for_loading_and_statistics(self):
        self.assert_driver_table_selection(explicit=True)

    def assert_driver_table_selection(self, explicit):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / '_benchmark_manifest.json').write_text('{invalid colocated metadata')
            manifest = root / 'chosen.json'
            tables = {'orders': {'date_partition_column': 'order_day'}, 'customers': {}}
            manifest.write_text(json.dumps({'tables': tables}))
            session = Mock()
            session.conf.get.return_value = 'app'
            builder = Mock()
            builder.appName.return_value.getOrCreate.return_value = session
            loaded = {}
            def setup(*args):
                loaded['tables'] = args[8]
                return args[4]
            def analyze(spark, mode, names, folder):
                loaded['analyzed'] = list(names)
                return {'duration_ms': 0}
            with patch.object(driver.SparkSession, 'builder', builder), \
                    patch.object(driver, 'setup_tables', side_effect=setup), \
                    patch.object(driver, 'analyze_catalog', side_effect=analyze), \
                    patch.object(driver, 'Profiler'), patch.object(driver, 'clearQueryName'), \
                    contextlib.redirect_stdout(io.StringIO()):
                driver.run_query_stream(
                    str(root), None, {}, str(root / 'times.csv'), None, None, None, 0, 1, None,
                    analyze='all_columns', dataset_manifest=str(manifest) if explicit else None)
            expected = list(tables) if explicit else list(driver.get_schemas(False))
            self.assertEqual(list(loaded['tables']), expected)
            self.assertEqual({table['format'] for table in loaded['tables'].values()}, {'parquet'})
            self.assertEqual(loaded['analyzed'], expected)
            dates = {name: table['date_partition_column']
                     for name, table in loaded['tables'].items()
                     if table['date_partition_column'] is not None}
            self.assertEqual(dates, {'orders': 'order_day'} if explicit
                             else driver.DATE_PARTITION_COLUMNS)


if __name__ == '__main__':
    unittest.main()
