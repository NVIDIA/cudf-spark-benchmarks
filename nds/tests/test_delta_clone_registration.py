# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check run-scoped Delta clone registration in both power drivers."""

import importlib.util
from datetime import datetime
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, call, patch


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_maintenance
import nds_power
from delta_clone import DeltaCloneScope


sys.path.insert(0, str(ROOT / 'nds-h'))
spec = importlib.util.spec_from_file_location('nds_h_delta_power', ROOT / 'nds-h/nds_h_power.py')
nds_h_power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nds_h_power)


class DeltaCloneRegistrationTest(unittest.TestCase):
    def test_delta_run_templates_forward_optional_warehouse_as_one_argument(self):
        templates = ('power_run_cpu_delta.template', 'power_run_gpu_delta.template',
                     'maintenance_delta.template')
        for template in templates:
            for warehouse in (None, 'hdfs://storage/clone warehouse'):
                with self.subTest(template=template, warehouse=warehouse):
                    environment = os.environ.copy()
                    environment.pop('DELTA_CLONE_WAREHOUSE', None)
                    if warehouse is not None:
                        environment['DELTA_CLONE_WAREHOUSE'] = warehouse
                    result = subprocess.run(
                        ['bash', '-c', 'source "$1"; printf "%s\\0" "${SPARK_CONF[@]}"',
                         'template-test', template], cwd=ROOT / 'nds', env=environment,
                        check=True, capture_output=True, text=True)
                    arguments = result.stdout.rstrip('\0').split('\0')
                    settings = [arguments[index + 1] for index, argument in enumerate(arguments)
                                if argument == '--conf']
                    warehouses = [value for value in settings
                                  if value.startswith('spark.sql.warehouse.dir=')]
                    self.assertEqual(warehouses, [] if warehouse is None else
                                     ['spark.sql.warehouse.dir=' + warehouse])

    def test_bundled_delta_templates_use_clone_capable_release(self):
        coordinate = 'io.delta:delta-core_2.12:2.3.0'
        template_names = (
            'convert_submit_cpu_delta.template',
            'maintenance_delta.template',
            'power_run_cpu_delta.template',
            'power_run_gpu_delta.template',
        )

        for template_name in template_names:
            with self.subTest(template=template_name):
                template = (ROOT / 'nds' / template_name).read_text()
                self.assertIn(coordinate, template)
                self.assertNotIn('io.delta:delta-core_2.12:2.1.1', template)

    def test_nds_registers_every_delta_path_in_one_clone_scope(self):
        spark = Mock()
        spark.conf.get.return_value = 'application-nds'
        scope = Mock()
        with patch.object(nds_power, 'DeltaCloneScope', return_value=scope) as scope_type, \
                patch.object(nds_power, 'get_schemas', return_value={'customer': None,
                                                                    'store_sales': None}), \
                patch.object(nds_power.time, 'time', side_effect=[1.000, 1.010, 2.000, 2.025]):
            times, returned_scope = nds_power.register_delta_tables(
                spark, 'abfss://container/reference/', [])

        scope_type.assert_called_once_with(spark, 'nds_delta_run')
        self.assertEqual(scope.clone_table.call_args_list, [
            call('abfss://container/reference/customer', 'customer'),
            call('abfss://container/reference/store_sales', 'store_sales'),
        ])
        self.assertEqual(times, [
            ('application-nds', 'ShallowClone customer', 10),
            ('application-nds', 'ShallowClone store_sales', 25),
        ])
        self.assertIs(returned_scope, scope)

    def test_nds_h_closes_clone_scope_if_registration_fails(self):
        spark = Mock()
        spark.conf.get.return_value = 'application-nds-h'
        scope = Mock()
        scope.clone_table.side_effect = RuntimeError('clone failed')
        with patch.object(nds_h_power, 'DeltaCloneScope', return_value=scope), \
                patch.object(nds_h_power, 'get_schemas', return_value={'lineitem': None}):
            with self.assertRaisesRegex(RuntimeError, 'clone failed'):
                nds_h_power.register_delta_tables(spark, '/reference', [])

        scope.clone_table.assert_called_once_with('/reference/lineitem', 'lineitem')
        scope.close.assert_called_once_with()

    def test_registration_keeps_clone_error_if_drop_also_fails(self):
        spark = Mock()
        spark.catalog.currentDatabase.return_value = 'default'
        clone_error = RuntimeError('clone failed')
        spark.sql.side_effect = [None, clone_error, RuntimeError('drop failed')]
        with patch.object(nds_h_power, 'get_schemas', return_value={'lineitem': None}), \
                self.assertLogs('delta_clone', level='WARNING'):
            with self.assertRaises(RuntimeError) as raised:
                nds_h_power.register_delta_tables(spark, '/reference', [])
        self.assertIs(raised.exception, clone_error)

    def test_nds_power_closes_clone_scope_on_failure_and_stops_session(self):
        shared_spark = Mock()
        shared_spark._jsparkSession.conf().getAll().iterator().hasNext.return_value = False
        spark = Mock()
        spark.conf.get.return_value = 'application-nds'
        shared_spark.newSession.return_value = spark
        builder = Mock()
        builder.appName.return_value.getOrCreate.return_value = shared_spark
        scope = Mock()
        error = RuntimeError('query setup failed')

        with tempfile.TemporaryDirectory() as directory, \
                patch.object(nds_power.SparkSession, 'builder', builder), \
                patch.object(nds_power, 'register_delta_tables',
                             return_value=([], scope)) as register_delta_tables, \
                patch.object(nds_power, 'check_json_summary_folder', side_effect=error):
            with self.assertRaises(RuntimeError) as stopped:
                nds_power.run_query_stream(
                    '/reference', None, {}, str(Path(directory) / 'times.csv'), None,
                    None, None, 0, 1, ['logical'], input_format='delta',
                    delta_unmanaged=True)

        self.assertIs(stopped.exception, error)
        shared_spark.newSession.assert_called_once_with()
        register_delta_tables.assert_called_once_with(spark, '/reference', [])
        scope.close.assert_called_once_with()
        spark.stop.assert_called_once_with()

    def test_nds_h_power_closes_clone_scope_on_failure_and_stops_session(self):
        shared_spark = Mock()
        shared_spark._jsparkSession.conf().getAll().iterator().hasNext.return_value = False
        spark = Mock()
        spark.conf.get.return_value = 'application-nds-h'
        shared_spark.newSession.return_value = spark
        builder = Mock()
        builder.appName.return_value.getOrCreate.return_value = shared_spark
        scope = Mock()
        error = RuntimeError('query setup failed')

        with tempfile.TemporaryDirectory() as directory, \
                patch.object(nds_h_power.SparkSession, 'builder', builder), \
                patch.object(nds_h_power, 'register_delta_tables',
                             return_value=([], scope)) as register_delta_tables, \
                patch.object(nds_h_power, 'check_json_summary_folder', side_effect=error):
            with self.assertRaises(RuntimeError) as stopped:
                nds_h_power.run_query_stream(
                    '/reference', None, {}, str(Path(directory) / 'times.csv'),
                    None, 0, 1, ['logical'], 'delta')

        self.assertIs(stopped.exception, error)
        shared_spark.newSession.assert_called_once_with()
        register_delta_tables.assert_called_once_with(spark, '/reference', [])
        scope.close.assert_called_once_with()
        spark.stop.assert_called_once_with()

    def test_maintenance_uses_run_owned_session_for_unmanaged_delta(self):
        shared_spark = Mock()
        shared_spark._jsparkSession.conf().getAll().iterator().hasNext.return_value = False
        run_spark = Mock()
        shared_spark.newSession.return_value = run_spark
        builder = Mock()
        builder.config.return_value = builder
        builder.appName.return_value.getOrCreate.return_value = shared_spark

        with patch.object(nds_maintenance.SparkSession, 'builder', builder):
            returned = nds_maintenance.create_spark_session(
                ['DF_CS'], '/reference', 'delta', delta_unmanaged=True)

        shared_spark.newSession.assert_called_once_with()
        self.assertIs(returned, run_spark)

    def test_power_drivers_write_results_when_clone_drop_fails(self):
        cases = [
            (nds_power, (None, None, None, 0, 1, ['logical']),
             {'input_format': 'delta', 'delta_unmanaged': True}),
            (nds_h_power, (None, 0, 1, ['logical'], 'delta'), {}),
        ]
        for driver, arguments, keywords in cases:
            with self.subTest(driver=driver.__name__), tempfile.TemporaryDirectory() as directory:
                shared_spark = Mock()
                shared_spark._jsparkSession.conf().getAll().iterator().hasNext.return_value = False
                spark = shared_spark.newSession.return_value
                spark.conf.get.return_value = 'application-delta'
                spark.catalog.currentDatabase.return_value = 'default'
                scope = DeltaCloneScope(spark, 'nds_delta_run')
                spark.sql.side_effect = RuntimeError('drop failed')
                builder = Mock()
                builder.appName.return_value.getOrCreate.return_value = shared_spark
                report = Path(directory) / 'times.csv'

                with patch.object(driver.SparkSession, 'builder', builder), \
                        patch.object(driver, 'register_delta_tables', return_value=([], scope)), \
                        patch.object(driver, 'setQueryName'), \
                        patch.object(driver, 'clearQueryName'), \
                        self.assertLogs('delta_clone', level='WARNING'):
                    driver.run_query_stream(
                        '/reference', None, {}, str(report), *arguments,
                        keep_sc=True, allow_failure=True, **keywords)
                self.assertIn('Power Test Time', report.read_text())

    def test_maintenance_closes_clone_scope_on_query_failure_and_stops_context(self):
        spark = Mock()
        spark.sparkContext.applicationId = 'application-maintenance'
        spark.catalog.currentDatabase.return_value = 'default'
        scope = DeltaCloneScope(spark, 'nds_delta_run')
        spark.sql.side_effect = RuntimeError('drop failed')
        report = Mock()
        error = RuntimeError('maintenance query failed')
        report.report_on.side_effect = error

        with tempfile.TemporaryDirectory() as directory, \
                patch.object(nds_maintenance, 'register_delta_tables',
                             return_value=([], scope)), \
                patch.object(nds_maintenance, 'PysparkBenchReport', return_value=report), \
                patch.object(nds_maintenance, 'setQueryName'), \
                self.assertLogs('delta_clone', level='WARNING'):
            with self.assertRaises(RuntimeError) as stopped:
                nds_maintenance.run_query(
                    spark, {'DF_CS': ['DELETE FROM catalog_sales']},
                    str(Path(directory) / 'times.csv'), None, None,
                    '/reference', 'delta', False, delta_unmanaged=True)

        self.assertIs(stopped.exception, error)
        spark.sql.assert_called_with('DROP DATABASE `{}` CASCADE'.format(scope.database_name))
        spark.sparkContext.stop.assert_called_once_with()

    def test_maintenance_time_excludes_clone_setup_and_cleanup(self):
        spark = Mock()
        spark.sparkContext.applicationId = 'application-maintenance'
        scope = Mock()
        report = Mock()
        report.report_on.return_value = {'queryTimes': 250}
        clock = Mock()
        events = []
        timestamps = iter([
            datetime(2026, 10, 15, 0, 0, 0),
            datetime(2026, 10, 15, 0, 0, 10),
            datetime(2026, 10, 15, 0, 0, 20),
            datetime(2026, 10, 15, 0, 0, 30),
        ])

        def now():
            timestamp = next(timestamps)
            events.append('time-{}'.format(timestamp.second))
            return timestamp

        def register_delta_tables(*_):
            events.append('clone-setup')
            return [], scope

        clock.now.side_effect = now
        scope.close.side_effect = lambda: events.append('clone-cleanup')
        report.report_on.side_effect = lambda *_: (
            events.append('dml') or {'queryTimes': 250})

        with tempfile.TemporaryDirectory() as directory, \
                patch.object(nds_maintenance, 'datetime', clock), \
                patch.object(nds_maintenance, 'register_delta_tables',
                             side_effect=register_delta_tables), \
                patch.object(nds_maintenance, 'PysparkBenchReport', return_value=report), \
                patch.object(nds_maintenance, 'setQueryName'), \
                patch.object(nds_maintenance, 'clearQueryName'):
            report_path = Path(directory) / 'times.csv'
            nds_maintenance.run_query(
                spark, {'DF_CS': ['DELETE FROM catalog_sales']},
                str(report_path), None, None,
                '/reference', 'delta', True, delta_unmanaged=True)

            rows = report_path.read_text().splitlines()

        self.assertEqual(events, [
            'time-0',
            'clone-setup',
            'time-10',
            'dml',
            'time-20',
            'clone-cleanup',
            'time-30',
        ])
        self.assertIn('application-maintenance,Data Maintenance Time,10.0', rows)
        self.assertIn('application-maintenance,Total Time,30.0', rows)


if __name__ == '__main__':
    unittest.main()
