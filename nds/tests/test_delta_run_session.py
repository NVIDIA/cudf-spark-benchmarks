# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check requested Delta run settings with an existing real Spark session."""

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from pyspark.sql import SparkSession
from pyspark.sql.utils import AnalysisException

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power
from delta_clone import DeltaCloneScope, new_run_session

sys.path.insert(0, str(ROOT / 'nds-h'))
spec = importlib.util.spec_from_file_location('nds_h_session_power', ROOT / 'nds-h/nds_h_power.py')
nds_h_power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nds_h_power)


class DeltaRunSessionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]')
                     .appName('delta-run-session-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '3')
                     .config('spark.sql.caseSensitive', 'false')
                     .config('spark.rapids.sql.enabled', 'true')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def _check_properties(self, driver, arguments, keywords):
        properties = {
            'spark.sql.shuffle.partitions': '7',
            'spark.sql.caseSensitive': 'true',
            'spark.rapids.sql.enabled': 'false',
            # Spark normalizes this raw path to a file: URI at startup.
            'spark.sql.warehouse.dir': str(self.root / 'warehouse'),
            'spark.master': 'local[2]',
        }
        property_file = self.root / 'requested.properties'
        property_file.write_text(''.join('{}={}\n'.format(k, v) for k, v in properties.items()))
        self.spark.sql('SELECT 42 AS value').createOrReplaceTempView('caller_view')
        self.spark.conf.set('spark.sql.adaptive.enabled', 'false')
        caller_database = self.spark.catalog.currentDatabase()

        def inspect_run(spark, *_):
            self.assertIsNot(spark, self.spark)
            self.assertIs(spark.sparkContext, self.spark.sparkContext)
            for key, value in properties.items():
                expected = self.spark.conf.get(key) if key == 'spark.sql.warehouse.dir' else value
                self.assertEqual(spark.conf.get(key), expected, key)
            self.assertEqual(spark.conf.get('spark.sql.adaptive.enabled'), 'false')
            # Verify the setting actually changes SQL analysis, not only its label.
            with self.assertRaises(AnalysisException):
                spark.sql('SELECT mixed FROM (SELECT 1 AS MiXeD)')
            self.assertFalse(spark.catalog.tableExists('caller_view'))
            spark.conf.set('spark.sql.shuffle.partitions', '11')
            self.assertEqual(self.spark.conf.get('spark.sql.shuffle.partitions'), '7')
            raise RuntimeError('run settings verified')

        with patch.object(driver, 'register_delta_tables', side_effect=inspect_run) as register:
            with self.assertRaisesRegex(RuntimeError, 'run settings verified'):
                driver.run_query_stream(
                    '/reference', str(property_file), {}, str(self.root / 'times.csv'),
                    *arguments, keep_sc=True, **keywords)

        register.assert_called_once()
        self.assertEqual(self.spark.catalog.currentDatabase(), caller_database)
        self.assertEqual(self.spark.table('caller_view').first().value, 42)

    def test_nds_preserves_requested_settings_when_reusing_session(self):
        self._check_properties(nds_power, (None, None, None, 0, 1, ['logical']),
                               {'input_format': 'delta', 'delta_unmanaged': True})

    def test_nds_h_preserves_requested_settings_when_reusing_session(self):
        self._check_properties(nds_h_power, (None, 0, 1, ['logical'], 'delta'), {})

    def test_conflicting_static_setting_warns_and_keeps_application_value(self):
        with self.assertLogs('delta_clone', level='WARNING') as logs:
            run = new_run_session(self.spark, {
                'spark.sql.warehouse.dir': str(self.root / 'different-warehouse'),
            })
        self.assertEqual(run.conf.get('spark.sql.warehouse.dir'),
                         self.spark.conf.get('spark.sql.warehouse.dir'))
        self.assertIn('spark.sql.warehouse.dir', '\n'.join(logs.output))

    def test_caller_settings_are_inherited_before_property_overrides(self):
        self.spark.conf.set('spark.sql.adaptive.enabled', 'false')
        self.spark.conf.set('spark.sql.shuffle.partitions', '13')
        self.spark.conf.set('spark.rapids.sql.enabled', 'false')
        run = new_run_session(self.spark, {'spark.sql.shuffle.partitions': '17'})
        self.assertEqual(run.conf.get('spark.sql.adaptive.enabled'), 'false')
        self.assertEqual(run.conf.get('spark.rapids.sql.enabled'), 'false')
        self.assertEqual(run.conf.get('spark.sql.shuffle.partitions'), '17')
        self.assertEqual(self.spark.conf.get('spark.sql.shuffle.partitions'), '13')

    def test_clone_resolves_relative_path_against_hadoop_working_directory(self):
        path_type = self.spark._jvm.org.apache.hadoop.fs.Path
        filesystem = path_type('convert/delta_sf1/customer_address').getFileSystem(
            self.spark._jsparkSession.sessionState().newHadoopConf())
        previous_directory = filesystem.getWorkingDirectory()
        working_directory = self.root / 'hadoop-working-directory'
        working_directory.mkdir()
        filesystem.setWorkingDirectory(path_type(str(working_directory)))
        try:
            with DeltaCloneScope(self.spark, 'nds_path_test') as scope:
                with patch.object(self.spark, 'sql') as sql:
                    scope.clone_table('convert/delta_sf1/customer_address', 'customer_address')
                sql.assert_called_once_with(
                    'CREATE TABLE `{}`.`customer_address` SHALLOW CLONE delta.`file:{}`'.format(
                        scope.database_name, working_directory / 'convert/delta_sf1/customer_address'))
        finally:
            filesystem.setWorkingDirectory(previous_directory)

    def test_clone_preserves_absolute_paths_and_quoted_remote_uris(self):
        sources = ['/reference/customer_address', 'file:/reference/customer_address',
                   'hdfs://namenode/reference/customer_address',
                   's3a://bucket/reference/customer_address',
                   'abfss://container/reference`data/customer_address']
        with DeltaCloneScope(self.spark, 'nds_path_test') as scope:
            for source in sources:
                with self.subTest(source=source), patch.object(self.spark, 'sql') as sql:
                    scope.clone_table(source, 'customer_address')
                    sql.assert_called_once_with(
                        'CREATE TABLE `{}`.`customer_address` SHALLOW CLONE delta.`{}`'.format(
                            scope.database_name, source.replace('`', '``')))


if __name__ == '__main__':
    unittest.main()
