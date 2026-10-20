# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check partition registration with Spark's legacy literal settings."""

import datetime
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power as driver


class PartitionLiteralCompatibilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]')
                     .appName('partition-literal-compatibility-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_integer_date_and_string_partitions_work_with_legacy_literal_settings(self):
        day = datetime.date(2001, 1, 1)
        expected = {(1, 20, day, 'north'), (2, None, None, None)}
        path = self.root / 'ordinary'
        frame = self.spark.createDataFrame(
            list(expected), 'payload int, date_key int, event_day date, region string')
        frame.coalesce(1).write.partitionBy('date_key', 'event_day', 'region').parquet(str(path))
        selected = driver._partitions_at_cutoff(
            self.spark, str(path), 'date_key', lambda: {20: day}, day)
        keys = ('spark.sql.legacy.keepPartitionSpecAsStringLiteral',
                'spark.sql.parser.escapedStringLiterals')
        previous = [self.spark.conf.get(key) for key in keys]
        try:
            for keep in ('false', 'true'):
                for escaped in ('false', 'true'):
                    with self.subTest(keepPartitionSpecAsStringLiteral=keep,
                                      escapedStringLiterals=escaped):
                        self.spark.conf.set(keys[0], keep)
                        self.spark.conf.set(keys[1], escaped)
                        driver._create_data_source_table(
                            self.spark, 'ordinary_values', str(path), 'parquet',
                            frame.schema, selected)
                        try:
                            self.spark.sql('ANALYZE TABLE ordinary_values COMPUTE STATISTICS')
                            self.assertEqual(
                                {tuple(row) for row in self.spark.table('ordinary_values').collect()},
                                expected)
                        finally:
                            self.spark.sql('DROP TABLE IF EXISTS ordinary_values')
        finally:
            for key, value in zip(keys, previous):
                self.spark.conf.set(key, value)

    def test_special_partition_values_are_rejected_before_legacy_catalog_registration(self):
        day = datetime.date(2001, 1, 1)
        path = self.root / 'special'
        frame = self.spark.createDataFrame(
            [(1, day, "o'neil"), (2, day, 'back\\slash')],
            'payload int, event_day date, region string')
        frame.coalesce(1).write.partitionBy('event_day', 'region').parquet(str(path))
        selected = driver._partitions_at_cutoff(
            self.spark, str(path), 'event_day', lambda: {}, day)
        key = 'spark.sql.legacy.keepPartitionSpecAsStringLiteral'
        previous = self.spark.conf.get(key)
        try:
            self.spark.conf.set(key, 'true')
            with self.assertRaisesRegex(ValueError, key.replace('.', r'\.') + '=false'):
                driver._create_data_source_table(
                    self.spark, 'special_values', str(path), 'parquet', frame.schema, selected)
            self.assertFalse(self.spark.catalog.tableExists('special_values'))
        finally:
            self.spark.conf.set(key, previous)


if __name__ == '__main__':
    unittest.main()
