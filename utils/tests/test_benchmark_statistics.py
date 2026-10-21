# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test statistics helpers and actual drivers without starting Spark."""

import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import sys
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'utils'))
import benchmark_statistics as statistics


def load_driver(folder, script):
    sys.path.insert(0, str(ROOT / folder))
    spec = importlib.util.spec_from_file_location('statistics_' + folder, ROOT / folder / script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BenchmarkStatisticsTest(unittest.TestCase):
    def test_statistics_cleanup_removes_only_its_reserved_file(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory) / 'statistics'
            folder.mkdir()
            cost = folder / 'analyze-cost.json'
            cost.write_text('old analysis')
            other = folder / 'notes.txt'
            other.write_text('keep me')
            statistics.clear_statistics_summary(directory)
            statistics.clear_statistics_summary(directory)
            statistics.clear_statistics_summary(None)
            self.assertFalse(cost.exists())
            self.assertEqual(other.read_text(), 'keep me')

    def test_fresh_catalog_guard_rejects_existing_targets_without_running_sql(self):
        session = SimpleNamespace(
            catalog=SimpleNamespace(currentDatabase=lambda: 'caller',
                                    tableExists=lambda name: name.endswith('.`facts`')),
            sql=Mock(side_effect=AssertionError('Preflight must not create tables')))
        with self.assertRaisesRegex(ValueError, 'fresh catalog tables'):
            statistics.require_fresh_catalog_tables(session, ['fresh', 'facts'])

    def test_fresh_catalog_guards_work_before_pyspark_exposed_table_exists(self):
        session = SimpleNamespace(
            catalog=SimpleNamespace(currentDatabase=lambda: 'caller'),
            _jsparkSession=Mock(),
            sql=Mock(side_effect=AssertionError('Preflight must not create tables')))
        exists = session._jsparkSession.catalog.return_value.tableExists
        exists.side_effect = lambda name: name.endswith('.`facts`')
        with self.assertRaisesRegex(ValueError, 'fresh catalog tables'):
            statistics.require_fresh_catalog_tables(session, ['fresh', 'facts'])
        self.assertEqual([call.args[0] for call in exists.call_args_list],
                         ['`caller`.`fresh`', '`caller`.`facts`'])
        driver = load_driver('nds', 'nds_power.py')
        driver._require_fresh_catalog_table(session, 'fresh')
        with self.assertRaisesRegex(ValueError, 'fresh catalog table'):
            driver._require_fresh_catalog_table(session, 'facts')

    def test_mode_costs_and_optional_json(self):
        for mode in ('table', 'all_columns'):
            for save_json in (False, True):
                with self.subTest(mode=mode, save_json=save_json), tempfile.TemporaryDirectory() as directory:
                    session = SimpleNamespace(sql=Mock())
                    with patch.object(statistics.time, 'perf_counter_ns',
                                      side_effect=[0, 1000000, 5000000, 6000000]):
                        report = statistics.analyze_catalog(
                            session, mode, ['facts'], directory if save_json else None)
                    expected = {'mode': mode, 'duration_ms': 6,
                                'tables': [{'table': 'facts', 'duration_ms': 4}]}
                    self.assertEqual(report, expected)
                    cost = Path(directory) / 'statistics/analyze-cost.json'
                    self.assertEqual(cost.exists(), save_json)
                    if save_json:
                        self.assertEqual(json.loads(cost.read_text()), expected)

    def test_disabled_helper_has_no_statistics_output_or_json(self):
        for mode in (None, 'none'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                session = SimpleNamespace(sql=Mock(side_effect=AssertionError('Analysis was disabled')))
                with contextlib.redirect_stdout(io.StringIO()) as output:
                    report = statistics.analyze_catalog(session, mode, ['facts'], directory)
                self.assertEqual(report['duration_ms'], 0)
                self.assertEqual(report['tables'], [])
                self.assertEqual(output.getvalue(), '')
                self.assertFalse((Path(directory) / 'statistics').exists())

    def test_cli_analysis_flags_are_mutually_exclusive_in_both_orders(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            for mode in ('none', 'table', 'all_columns'):
                for flags in (['--analyze_tables', '--analyze', mode],
                              ['--analyze', mode, '--analyze_tables']):
                    with self.subTest(driver=folder, flags=flags):
                        result = subprocess.run(
                            [sys.executable, str(ROOT / folder / script), '/facts', 'stream.sql',
                             'times.csv', *flags], capture_output=True, text=True, timeout=15)
                        self.assertEqual(result.returncode, 2)
                        self.assertIn('not allowed with argument', result.stderr)

    def test_disabled_modes_and_legacy_warning_preserve_input_provider_behavior(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            driver = load_driver(folder, script)
            cases = [('parquet', {}), ('delta', {}), ('iceberg', {}),
                     ('parquet', {'spark_connect': 'sc://server'})]
            if folder == 'nds':
                cases.append(('parquet', {'hive_external': True}))
            for input_format, extra in cases:
                configurations = []
                for mode, legacy in ((None, False), ('none', False), (None, True)):
                    with self.subTest(driver=folder, mode=mode, legacy=legacy, input_format=input_format,
                                      extra=extra), tempfile.TemporaryDirectory() as directory:
                        settings = {'spark.sql.defaultCatalog': 'custom',
                                    'spark.sql.warehouse.dir': '/caller/warehouse'}
                        session = Mock()
                        session.conf.get.return_value = 'app'
                        builder = Mock()
                        builder.config.side_effect = lambda key, value: settings.update({key: value}) or builder
                        builder.remote.return_value = builder
                        builder.enableHiveSupport.return_value = builder
                        builder.appName.return_value.getOrCreate.return_value = session
                        options = dict(input_prefix='/data', property_file=None, query_dict={},
                                       time_log_output_path=str(Path(directory) / 'time.csv'),
                                       sub_queries=None, warmup_iterations=0, iterations=1,
                                       plan_types=None, input_format=input_format, analyze=mode,
                                       allow_failure=True, analyze_tables=legacy, **extra)
                        if folder == 'nds':
                            options.update(extra_time_log_output_path=None, sub_query_patterns=None)
                        with patch.object(driver.SparkSession, 'builder', builder), \
                                patch.object(driver, 'setup_tables',
                                             side_effect=lambda *args: args[4 if folder == 'nds' else 3]), \
                                patch.object(driver, 'register_delta_tables',
                                             side_effect=lambda *args: args[2]), \
                                patch.object(driver, 'analyze_catalog',
                                             side_effect=AssertionError('Analysis was disabled')), \
                                patch.object(driver, 'Profiler', return_value=lambda **args: contextlib.nullcontext()), \
                                patch.object(driver, 'clearQueryName'), \
                                contextlib.redirect_stdout(io.StringIO()), \
                                contextlib.redirect_stderr(io.StringIO()) as warning:
                            driver.run_query_stream(**options)
                        if legacy:
                            self.assertIn('deprecated', warning.getvalue())
                            self.assertIn('--analyze table', warning.getvalue())
                        else:
                            self.assertEqual(warning.getvalue(), '')
                        configurations.append(settings)
                        with Path(options['time_log_output_path']).open() as stream:
                            names = [row['query'] for row in csv.DictReader(stream)]
                        self.assertNotIn('Statistics Time', names)
                        self.assertFalse((Path(directory) / 'statistics').exists())
                self.assertEqual(configurations[0], configurations[1])
                self.assertEqual(configurations[0], configurations[2])

    def test_selected_catalog_registration_keeps_root_recovery_disabled(self):
        driver = load_driver('nds', 'nds_power.py')
        catalog = SimpleNamespace(
            tableExists=lambda name: False, currentDatabase=lambda: 'default',
            dropTempView=lambda name: None,
            recoverPartitions=Mock(side_effect=AssertionError('Would load unselected partitions')))
        session = SimpleNamespace(catalog=catalog, sql=Mock(),
                                  conf=SimpleNamespace(get=lambda *args: 'true', set=Mock()))
        with contextlib.redirect_stdout(io.StringIO()) as output:
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet',
                partitions=[({'day_key': '2'}, '/facts/day_key=2'),
                            ({'day_key': '__HIVE_DEFAULT_PARTITION__'}, '/facts/day_key=__HIVE_DEFAULT_PARTITION__')])
        self.assertNotIn('/facts/day_key=', output.getvalue())
        catalog.tableExists = lambda name: True
        with self.assertRaisesRegex(ValueError, 'fresh catalog'):
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet', partitions=[({'day_key': '2'}, '/facts/day_key=2')])
        session.conf.get = lambda *args: 'false'
        with self.assertRaisesRegex(ValueError, 'manageFilesourcePartitions=true'):
            driver._create_data_source_table(
                session, 'facts', '/facts', 'parquet', partitions=[({'day_key': '2'}, '/facts/day_key=2')])

    def test_actual_driver_guards_reject_legacy_connect_and_external_hive(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            driver = load_driver(folder, script)
            options = dict(input_prefix='/data', property_file=None, query_dict={},
                           time_log_output_path='time.csv', sub_queries=None,
                           warmup_iterations=0, iterations=1, plan_types=None, input_format='parquet')
            cases = [{'analyze_tables': True}, {'spark_connect': 'sc://server'},
                     {'input_format': 'delta'}, {'input_format': 'iceberg'}]
            if folder == 'nds':
                options.update(extra_time_log_output_path=None, sub_query_patterns=None)
                cases.append({'hive_external': True})
            with self.assertRaisesRegex(ValueError, '--analyze'):
                driver.run_query_stream(**options, analyze='none', analyze_tables=True)
            for extra in cases:
                with self.subTest(driver=folder, options=extra), self.assertRaisesRegex(ValueError, '--analyze'):
                    driver.run_query_stream(**dict(options, analyze='all_columns', **extra))

    def test_ndsh_nonempty_summary_folder_still_rejects_before_artifact_cleanup(self):
        driver = load_driver('nds-h', 'nds_h_power.py')
        spec = importlib.util.spec_from_file_location('shared_summary_check', ROOT / 'utils/check.py')
        check = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(check)
        with tempfile.TemporaryDirectory() as directory:
            cost = Path(directory) / 'statistics/analyze-cost.json'
            cost.parent.mkdir()
            cost.write_text('old analysis')
            builder = Mock()
            builder.appName.return_value.getOrCreate.return_value.conf.get.return_value = 'app'
            with patch.object(driver.SparkSession, 'builder', builder), \
                    patch.object(driver, 'setup_tables', side_effect=lambda *args: args[3]), \
                    patch.object(driver, 'check_json_summary_folder', check.check_json_summary_folder):
                with self.assertRaisesRegex(Exception, 'not empty'):
                    driver.run_query_stream('/facts', None, {}, str(Path(directory) / 'time.csv'),
                                            None, 0, 1, None, 'parquet', json_summary_folder=directory,
                                            analyze='none', allow_failure=True)
            self.assertEqual(cost.read_text(), 'old analysis')

    def test_analysis_preserves_timing_csv_rows_and_excludes_cost_from_power_time(self):
        for folder, script in (('nds', 'nds_power.py'), ('nds-h', 'nds_h_power.py')):
            driver = load_driver(folder, script)
            expected_rows = None
            for mode in (None, 'none', 'table', 'all_columns'):
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
                    self.assertNotIn('Statistics Time', values)
                    if expected_rows is None:
                        expected_rows = rows
                    self.assertEqual(rows, expected_rows)


if __name__ == '__main__':
    unittest.main()
