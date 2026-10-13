# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check partition visibility and statistics through both power-driver helpers."""

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power


sys.path.insert(0, str(ROOT / 'nds-h'))
spec = importlib.util.spec_from_file_location('nds_h_power', ROOT / 'nds-h/nds_h_power.py')
nds_h_power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nds_h_power)


class PartitionRegistrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('partition-registration-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.hive.manageFilesourcePartitions', 'true')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        cls.spark.createDataFrame([(1, 1), (2, 2), (3, None)], 'payload int, day_key int') \
            .coalesce(1).write.partitionBy('day_key').parquet(str(cls.root / 'dated'))
        cls.spark.createDataFrame([(7,), (8,)], 'payload int').coalesce(1).write.parquet(
            str(cls.root / 'plain'))

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def check_registration(self, dataset, expected_rows):
        for name, driver in (('nds', nds_power), ('ndsh', nds_h_power)):
            table = name + '_' + dataset
            with self.subTest(driver=name, dataset=dataset):
                try:
                    driver._create_data_source_table(
                        self.spark, table, str(self.root / dataset), 'parquet')
                    self.assertEqual({tuple(row) for row in self.spark.table(table).collect()},
                                     expected_rows)
                    self.spark.sql('ANALYZE TABLE ' + table + ' COMPUTE STATISTICS')
                    statistics = [row.data_type for row in self.spark.sql(
                        'DESCRIBE EXTENDED ' + table).collect() if row.col_name == 'Statistics']
                    self.assertEqual(len(statistics), 1)
                    self.assertRegex(statistics[0], r'\b' + str(len(expected_rows)) + r' rows\b')
                finally:
                    self.spark.sql('DROP TABLE IF EXISTS ' + table)

    def test_partitioned_rows_including_null_are_visible_before_statistics(self):
        self.check_registration('dated', {(1, 1), (2, 2), (3, None)})

    def test_unpartitioned_rows_and_statistics_remain_visible(self):
        self.check_registration('plain', {(7,), (8,)})


if __name__ == '__main__':
    unittest.main()
