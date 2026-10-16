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
from delta_clone import new_run_session

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
            # These settings cannot be set with RuntimeConfig.set, even to the
            # same value. They must remain available from session/context startup.
            'spark.sql.warehouse.dir': self.spark.conf.get('spark.sql.warehouse.dir'),
            'spark.master': 'local[2]',
        }
        property_file = self.root / 'requested.properties'
        property_file.write_text(''.join('{}={}\n'.format(k, v) for k, v in properties.items()))
        self.spark.sql('SELECT 42 AS value').createOrReplaceTempView('caller_view')
        caller_database = self.spark.catalog.currentDatabase()

        def inspect_run(spark, *_):
            self.assertIsNot(spark, self.spark)
            self.assertIs(spark.sparkContext, self.spark.sparkContext)
            for key, value in properties.items():
                self.assertEqual(spark.conf.get(key), value, key)
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

    def test_conflicting_static_setting_is_rejected(self):
        with self.assertRaises(AnalysisException):
            new_run_session(self.spark, {
                'spark.sql.warehouse.dir': str(self.root / 'different-warehouse'),
            })


if __name__ == '__main__':
    unittest.main()
