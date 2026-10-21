# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check catalog registration preserves partition values and source locations."""

import datetime
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds-h'))
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power
import nds_h_power


class PartitionValuesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('partition-values-tests')
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

    def test_analyzed_partitions_preserve_values_with_either_parser_setting(self):
        values = ["o'neil", 'back\\slash', 'both\'and"quotes\\', 'é', None]
        day = datetime.date(2001, 1, 1)
        expected = {(index, day, value) for index, value in enumerate(values)}
        path = self.root / 'partitions'
        frame = self.spark.createDataFrame(list(expected), 'payload int, event_day date, region string')
        frame.coalesce(1).write.partitionBy('event_day', 'region').parquet(str(path))
        selected = nds_power._partitions_at_cutoff(
            self.spark, str(path), 'event_day', lambda: {}, day)
        selected_frame = self.spark.read.option('basePath', str(path)).parquet(
            *[directory for _, directory in selected])
        self.assertEqual({tuple(row) for row in selected_frame.collect()}, expected)
        setting = self.spark.conf.get('spark.sql.parser.escapedStringLiterals')
        try:
            for mode in ('false', 'true'):
                with self.subTest(escapedStringLiterals=mode):
                    self.spark.conf.set('spark.sql.parser.escapedStringLiterals', mode)
                    nds_power._create_data_source_table(
                        self.spark, 'partition_values', str(path), 'parquet',
                        selected_frame.schema, selected)
                    try:
                        self.spark.sql('ANALYZE TABLE partition_values COMPUTE STATISTICS')
                        self.assertEqual(
                            {tuple(row) for row in self.spark.table('partition_values').collect()},
                            expected)
                    finally:
                        self.spark.sql('DROP TABLE IF EXISTS partition_values')
        finally:
            self.spark.conf.set('spark.sql.parser.escapedStringLiterals', setting)

    def test_both_drivers_preserve_quoted_source_paths_with_either_parser_setting(self):
        path = self.root / 'source\'with"quotes'
        self.spark.createDataFrame([(7,)], 'payload int').coalesce(1).write.parquet(str(path))
        setting = self.spark.conf.get('spark.sql.parser.escapedStringLiterals')
        try:
            for driver in (nds_power, nds_h_power):
                for mode in ('false', 'true'):
                    with self.subTest(driver=driver.__name__, escapedStringLiterals=mode):
                        self.spark.conf.set('spark.sql.parser.escapedStringLiterals', mode)
                        driver._create_data_source_table(
                            self.spark, 'source_values', str(path), 'parquet')
                        try:
                            self.assertEqual(
                                [tuple(row) for row in self.spark.table('source_values').collect()],
                                [(7,)])
                        finally:
                            self.spark.sql('DROP TABLE IF EXISTS source_values')
        finally:
            self.spark.conf.set('spark.sql.parser.escapedStringLiterals', setting)


if __name__ == '__main__':
    unittest.main()
