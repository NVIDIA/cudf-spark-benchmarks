# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES.
# All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Statistics modes, isolation guards and driver timing without starting Spark."""

import ast
import contextlib
import csv
import inspect
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[1]


def functions(path, names, **namespace):
    tree = ast.parse(path.read_text())
    nodes = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in names]
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(path), 'exec'), namespace)
    return namespace


def statistics_functions(**values):
    import os
    import time
    import uuid
    return functions(ROOT / 'utils/benchmark_statistics.py',
                     {'isolated_session', 'analyze_catalog'},
                     os=os, time=time, uuid=uuid, tempfile=tempfile, json=json, **values)


class BenchmarkStatisticsTest(unittest.TestCase):
    def test_modes_issue_expected_sql_and_write_separate_cost(self):
        for mode, suffix in (('none', None), ('table', ''), ('column', ' FOR ALL COLUMNS')):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                clock = Mock(side_effect=[0, 1000000, 5000000, 6000000])
                helper = statistics_functions()
                helper['time'] = SimpleNamespace(perf_counter_ns=clock)
                session = SimpleNamespace(sql=Mock())
                report = helper['analyze_catalog'](session, mode, ['facts'], directory)
                if suffix is None:
                    session.sql.assert_not_called()
                    self.assertEqual(report, {'mode': 'none', 'duration_ms': 0, 'tables': []})
                else:
                    session.sql.assert_called_once_with(
                        'ANALYZE TABLE `facts` COMPUTE STATISTICS' + suffix)
                    self.assertEqual(report['tables'], [{'table': 'facts', 'duration_ms': 4}])
                    self.assertEqual(report['duration_ms'], 6)
                cost = Path(directory) / 'statistics/analyze-cost.json'
                self.assertEqual(json.loads(cost.read_text()), report)

    def test_isolation_rejects_invalid_mode_inputs_and_existing_session(self):
        session_api = SimpleNamespace(getActiveSession=Mock(return_value=None))
        helper = statistics_functions(SparkSession=session_api)['isolated_session']
        for mode, folder, fmt, message in (
                ('invalid', '/summary', 'parquet', 'analyze must'),
                ('column', None, 'parquet', 'json_summary_folder'),
                ('table', '/summary', 'iceberg', 'file-backed'),
                ('none', '/summary', 'delta', 'file-backed')):
            with self.subTest(mode=mode, fmt=fmt), self.assertRaisesRegex(ValueError, message):
                helper(Mock(), 'test', mode, folder, fmt)
        session_api.getActiveSession.return_value = object()
        with self.assertRaisesRegex(ValueError, 'fresh Spark driver'):
            helper(Mock(), 'test', 'column', '/summary', 'parquet')

    def test_isolation_creates_unique_catalog_and_rejects_reused_or_custom_catalog(self):
        for override in ({}, {'spark.sql.warehouse.dir': 'old'},
                         {'spark.sql.defaultCatalog': 'custom'},
                         {'spark.sql.catalog.spark_catalog': 'custom.Provider'}):
            with self.subTest(override=override):
                settings = {}
                session = SimpleNamespace(
                    conf=SimpleNamespace(get=lambda key, default=None:
                                         override.get(key, settings.get(key, default))),
                    sql=Mock(), catalog=SimpleNamespace(setCurrentDatabase=Mock()))
                builder = Mock()
                builder.config.side_effect = lambda key, value: settings.update({key: value}) or builder
                builder.appName.return_value = builder
                builder.getOrCreate.return_value = session
                helper = statistics_functions(
                    SparkSession=SimpleNamespace(getActiveSession=lambda: None))['isolated_session']
                if override:
                    with self.assertRaises(ValueError):
                        helper(builder, 'test', 'table', '/summary', 'parquet')
                else:
                    self.assertIs(helper(builder, 'test', 'table', '/summary', 'parquet'), session)
                    self.assertEqual(settings['spark.sql.catalogImplementation'], 'in-memory')
                    self.assertTrue(settings['spark.sql.warehouse.dir'].startswith('file:'))
                    database = session.catalog.setCurrentDatabase.call_args.args[0]
                    session.sql.assert_called_once_with('CREATE DATABASE ' + database)
                    self.assertTrue(database.startswith('benchmark_'))

    def test_selected_partition_registration_never_recovers_the_full_root(self):
        namespace = functions(ROOT / 'nds/nds_power.py',
                              {'_quote_identifier', '_quote_sql_string', '_schema_to_ddl',
                               '_create_data_source_table'})
        catalog = SimpleNamespace(tableExists=Mock(return_value=False),
                                  getTable=Mock(return_value=SimpleNamespace(isTemporary=False)),
                                  dropTempView=Mock(), listColumns=Mock(), recoverPartitions=Mock())
        session = SimpleNamespace(catalog=catalog, sql=Mock(),
                                  conf=SimpleNamespace(get=Mock(return_value='true')))
        field = SimpleNamespace(name='day_key',
                                dataType=SimpleNamespace(simpleString=lambda: 'int'))
        schema = SimpleNamespace(fields=[field])
        create = namespace['_create_data_source_table']
        with contextlib.redirect_stdout(io.StringIO()):
            create(session, 'facts', '/facts', 'parquet', schema,
                   [('2', '/facts/day_key=2'),
                    ('__HIVE_DEFAULT_PARTITION__', '/facts/day_key=__HIVE_DEFAULT_PARTITION__')],
                   'day_key')
        statements = [call.args[0] for call in session.sql.call_args_list]
        self.assertIn('PARTITIONED BY (`day_key`)', statements[0])
        self.assertEqual(len(statements), 3)
        self.assertIn("PARTITION (`day_key`='2') LOCATION '/facts/day_key=2'", statements[1])
        self.assertIn("PARTITION (`day_key`='__HIVE_DEFAULT_PARTITION__')", statements[2])
        catalog.listColumns.assert_not_called()
        catalog.recoverPartitions.assert_not_called()
        catalog.tableExists.return_value = True
        session.sql.reset_mock()
        with self.assertRaisesRegex(ValueError, 'fresh catalog table'):
            create(session, 'facts', '/facts', 'parquet', schema, [], 'day_key')
        session.sql.assert_not_called()

    def test_disabled_partition_management_rejects_only_selected_catalog_registration(self):
        namespace = functions(ROOT / 'nds/nds_power.py',
                              {'_quote_identifier', '_quote_sql_string', '_schema_to_ddl',
                               '_create_data_source_table'})
        catalog = SimpleNamespace(tableExists=Mock(), dropTempView=Mock(),
                                  listColumns=Mock(return_value=[SimpleNamespace(isPartition=True)]),
                                  recoverPartitions=Mock())
        session = SimpleNamespace(catalog=catalog, sql=Mock(),
                                  conf=SimpleNamespace(get=Mock(return_value='false')))
        create = namespace['_create_data_source_table']
        with self.assertRaisesRegex(ValueError, 'manageFilesourcePartitions=true'):
            create(session, 'facts', '/facts', 'parquet', partitions=[('1', '/facts/day_key=1')],
                   partition_column='day_key')
        session.sql.assert_not_called()
        catalog.tableExists.assert_not_called()
        catalog.dropTempView.assert_not_called()
        with contextlib.redirect_stdout(io.StringIO()):
            create(session, 'facts', '/facts', 'parquet')
        session.sql.assert_called_once()
        catalog.recoverPartitions.assert_called_once_with('facts')
        self.assertEqual(session.conf.get.call_count, 1)

    def test_driver_guards_reject_legacy_connect_and_external_hive(self):
        for file in ('nds/nds_power.py', 'nds-h/nds_h_power.py'):
            run = functions(ROOT / file, {'run_query_stream'})['run_query_stream']
            required = {name: None for name, parameter in inspect.signature(run).parameters.items()
                        if parameter.default is inspect.Parameter.empty}
            options = [{'analyze_tables': True}, {'spark_connect': 'sc://server'}]
            if file.startswith('nds/'):
                options.append({'hive_external': True})
            for option in options:
                with self.subTest(file=file, option=option), self.assertRaisesRegex(ValueError, '--analyze'):
                    run(**required, analyze='column', **option)

    def test_statistics_row_precedes_query_window_without_changing_total_wall_time(self):
        for file in ('nds/nds_power.py', 'nds-h/nds_h_power.py'):
            for mode in (None, 'column'):
                with self.subTest(file=file, mode=mode), tempfile.TemporaryDirectory() as directory:
                    session = SimpleNamespace(stop=Mock())
                    builder = Mock()
                    builder.appName.return_value = builder
                    builder.getOrCreate.return_value = session
                    nds = file.startswith('nds/')
                    clock = Mock(side_effect=[100, 130, 140, 150])
                    namespace = functions(
                        ROOT / file, {'run_query_stream'},
                        SparkSession=SimpleNamespace(builder=builder),
                        time=SimpleNamespace(time=clock),
                        isolated_session=Mock(return_value=session),
                        setup_tables=lambda *args: args[4 if nds else 3],
                        _get_app_id=lambda spark: 'app', get_schemas=lambda *args: {'facts': None},
                        check_json_summary_folder=lambda folder: None,
                        analyze_catalog=Mock(return_value={'duration_ms': 1000}),
                        Profiler=lambda **kwargs: None, clearQueryName=lambda spark: None,
                        csv=csv, sys=SimpleNamespace(exit=Mock()))
                    run = namespace['run_query_stream']
                    required = {name: None for name, parameter in inspect.signature(run).parameters.items()
                                if parameter.default is inspect.Parameter.empty}
                    output = Path(directory) / 'time.csv'
                    required.update(query_dict={}, time_log_output_path=str(output), input_format='parquet')
                    with contextlib.redirect_stdout(io.StringIO()):
                        run(**required, analyze=mode, json_summary_folder=directory)
                    rows = list(csv.reader(output.open()))
                    values = {row[1]: float(row[2]) for row in rows[1:]}
                    self.assertEqual(values['Power Start Time'], 130)
                    self.assertEqual(values['Power Test Time'], 10000)
                    self.assertEqual(values['Total Time'], 50000)
                    if mode is None:
                        self.assertNotIn('Statistics Time', values)
                        namespace['analyze_catalog'].assert_not_called()
                    else:
                        self.assertEqual(values['Statistics Time'], 1000)
                        self.assertLess([row[1] for row in rows].index('Statistics Time'),
                                        [row[1] for row in rows].index('Power Start Time'))


if __name__ == '__main__':
    unittest.main()
