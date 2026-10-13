# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES.
# All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test statistics helpers and actual drivers without starting Spark."""

import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import benchmark_statistics as statistics


ROOT = Path(__file__).resolve().parents[1]


def load_driver(folder, script):
    sys.path.insert(0, str(ROOT / folder))
    spec = importlib.util.spec_from_file_location('statistics_' + folder, ROOT / folder / script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BenchmarkStatisticsTest(unittest.TestCase):
    def test_mode_costs_and_optional_json(self):
        for mode in ('none', 'table', 'column'):
            for save_json in (False, True):
                with self.subTest(mode=mode, save_json=save_json), tempfile.TemporaryDirectory() as directory:
                    session = SimpleNamespace(sql=Mock())
                    with patch.object(statistics.time, 'perf_counter_ns',
                                      side_effect=[0, 1000000, 5000000, 6000000]):
                        report = statistics.analyze_catalog(
                            session, mode, ['facts'], directory if save_json else None)
                    expected = {'mode': mode, 'duration_ms': 0 if mode == 'none' else 6,
                                'tables': [] if mode == 'none' else
                                [{'table': 'facts', 'duration_ms': 4}]}
                    self.assertEqual(report, expected)
                    cost = Path(directory) / 'statistics/analyze-cost.json'
                    self.assertEqual(cost.exists(), save_json)
                    if save_json:
                        self.assertEqual(json.loads(cost.read_text()), expected)

    def test_isolation_allows_no_summary_and_preserves_catalog_guards(self):
        for override in ({}, {'spark.sql.warehouse.dir': 'old'},
                         {'spark.sql.defaultCatalog': 'custom'}):
            with self.subTest(override=override):
                settings = {}
                catalog = SimpleNamespace(database=None)
                catalog.setCurrentDatabase = lambda value: setattr(catalog, 'database', value)
                session = SimpleNamespace(
                    conf=SimpleNamespace(get=lambda key, default=None:
                                         override.get(key, settings.get(key, default))),
                    sql=Mock(), catalog=catalog)
                builder = Mock()
                builder.config.side_effect = lambda key, value: settings.update({key: value}) or builder
                builder.appName.return_value = builder
                builder.getOrCreate.return_value = session
                with patch.object(statistics.SparkSession, 'getActiveSession', return_value=None):
                    if override:
                        with self.assertRaises(ValueError):
                            statistics.isolated_session(builder, 'test', 'column', None, 'parquet')
                    else:
                        self.assertIs(statistics.isolated_session(
                            builder, 'test', 'column', None, 'parquet'), session)
                        self.assertEqual(settings['spark.sql.catalogImplementation'], 'in-memory')
                        self.assertTrue(catalog.database.startswith('benchmark_'))
        with patch.object(statistics.SparkSession, 'getActiveSession', return_value=object()):
            with self.assertRaisesRegex(ValueError, 'fresh Spark driver'):
                statistics.isolated_session(Mock(), 'test', 'column', None, 'parquet')
        for mode, fmt in (('invalid', 'parquet'), ('column', 'iceberg')):
            with self.subTest(mode=mode, input_format=fmt), self.assertRaises(ValueError):
                statistics.isolated_session(Mock(), 'test', mode, None, fmt)

    def test_selected_catalog_registration_keeps_root_recovery_disabled(self):
        driver = load_driver('nds', 'nds_power.py')
        catalog = SimpleNamespace(
            tableExists=lambda name: False, dropTempView=lambda name: None,
            recoverPartitions=Mock(side_effect=AssertionError('Would load unselected partitions')))
        session = SimpleNamespace(catalog=catalog, sql=Mock(),
                                  conf=SimpleNamespace(get=lambda *args: 'true'))
        with contextlib.redirect_stdout(io.StringIO()) as output:
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet',
                partitions=[('2', '/facts/day_key=2'),
                            ('__HIVE_DEFAULT_PARTITION__', '/facts/day_key=__HIVE_DEFAULT_PARTITION__')],
                partition_column='day_key')
        self.assertNotIn('/facts/day_key=', output.getvalue())
        catalog.tableExists = lambda name: True
        catalog.getTable = lambda name: SimpleNamespace(isTemporary=False)
        with self.assertRaisesRegex(ValueError, 'fresh catalog'):
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet', partitions=[('2', '/facts/day_key=2')],
                partition_column='day_key')
        session.conf.get = lambda *args: 'false'
        with self.assertRaisesRegex(ValueError, 'manageFilesourcePartitions=true'):
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet', partitions=[('2', '/facts/day_key=2')],
                partition_column='day_key')

    def test_actual_driver_guards_reject_legacy_connect_and_external_hive(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            driver = load_driver(folder, script)
            options = dict(input_prefix='/data', property_file=None, query_dict={},
                           time_log_output_path='time.csv', sub_queries=None,
                           warmup_iterations=0, iterations=1, plan_types=None, input_format='parquet')
            cases = [{'analyze_tables': True}, {'spark_connect': 'sc://server'}]
            if folder == 'nds':
                options.update(extra_time_log_output_path=None, sub_query_patterns=None)
                cases.append({'hive_external': True})
            for extra in cases:
                with self.subTest(driver=folder, options=extra), self.assertRaisesRegex(ValueError, '--analyze'):
                    driver.run_query_stream(**options, analyze='column', **extra)

    def test_actual_driver_statistics_cost_precedes_query_window_without_summary(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            driver = load_driver(folder, script)
            for mode in (None, 'column'):
                with self.subTest(driver=folder, mode=mode), tempfile.TemporaryDirectory() as directory:
                    session = Mock()
                    session.conf.get.return_value = 'app'
                    builder = Mock()
                    builder.appName.return_value.getOrCreate.return_value = session
                    options = dict(input_prefix='/data', property_file=None, query_dict={},
                                   time_log_output_path=str(Path(directory) / 'time.csv'), sub_queries=None,
                                   warmup_iterations=0, iterations=1, plan_types=None,
                                   input_format='parquet', analyze=mode)
                    if folder == 'nds':
                        options.update(extra_time_log_output_path=None, sub_query_patterns=None)
                    with patch.object(driver.SparkSession, 'builder', builder), \
                            patch.object(driver, 'isolated_session', return_value=session), \
                            patch.object(driver, 'setup_tables',
                                         side_effect=lambda *args: args[4 if folder == 'nds' else 3]), \
                            patch.object(driver, 'analyze_catalog', return_value={'duration_ms': 1000}), \
                            patch.object(driver, 'Profiler', return_value=lambda **args: contextlib.nullcontext()), \
                            patch.object(driver, 'clearQueryName'), \
                            patch.object(driver.time, 'time', side_effect=[100, 130, 140, 150]), \
                            contextlib.redirect_stdout(io.StringIO()):
                        if folder == 'nds-h':
                            with self.assertRaises(SystemExit) as stopped:
                                driver.run_query_stream(**options)
                            self.assertEqual(stopped.exception.code, 0)
                        else:
                            driver.run_query_stream(**options)
                    with Path(options['time_log_output_path']).open() as stream:
                        rows = list(csv.DictReader(stream))
                    values = {row['query']: float(row['time/milliseconds']) for row in rows}
                    self.assertEqual(values['Power Test Time'], 10000)
                    self.assertEqual(values['Total Time'], 50000)
                    if mode is None:
                        self.assertNotIn('Statistics Time', values)
                    else:
                        self.assertEqual(values['Statistics Time'], 1000)
                        names = [row['query'] for row in rows]
                        self.assertLess(names.index('Statistics Time'), names.index('Power Start Time'))


if __name__ == '__main__':
    unittest.main()
