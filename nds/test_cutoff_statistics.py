# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check selected input rows and legacy table statistics with real Spark."""

import datetime
from pathlib import Path
import tempfile
import unittest

from pyspark.sql import SparkSession

import nds_power as driver


class CutoffStatisticsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('cutoff-statistics-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.hive.manageFilesourcePartitions', 'true')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        for name in driver.get_schemas(False):
            target = str(cls.root / name)
            if name == 'date_dim':
                cls.spark.createDataFrame(
                    [(key, datetime.date(2001, 1, key)) for key in (1, 2, 3)],
                    'd_date_sk int, d_date date').coalesce(1).write.parquet(target)
            elif name in driver.DATE_PARTITION_COLUMNS:
                column = driver.DATE_PARTITION_COLUMNS[name]
                cls.spark.createDataFrame([(10, 1), (20, 2), (30, 3), (40, None)],
                                          'payload int, ' + column + ' int').coalesce(1) \
                    .write.partitionBy(column).parquet(target)
            else:
                cls.spark.createDataFrame([(1,), (2,)], 'payload int').coalesce(1) \
                    .write.parquet(target)

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def tearDown(self):
        for name in driver.get_schemas(False):
            self.spark.catalog.dropTempView(name)
            self.spark.sql('DROP TABLE IF EXISTS `' + name + '`')

    def assert_row_statistics(self, name, count):
        statistics = [row.data_type for row in self.spark.sql(
            'DESCRIBE EXTENDED `' + name + '`').collect() if row.col_name == 'Statistics']
        self.assertEqual(len(statistics), 1)
        self.assertRegex(statistics[0], r'\b' + str(count) + r' rows\b')

    def test_analysis_uses_only_selected_partitions_and_all_dimension_rows(self):
        driver.setup_tables(self.spark, str(self.root), 'parquet', False, [],
                            analyze_tables=True, cutoff_date=datetime.date(2001, 1, 2))
        for name, column in driver.DATE_PARTITION_COLUMNS.items():
            with self.subTest(table=name):
                self.assertFalse(self.spark.catalog.getTable(name).isTemporary)
                self.assertEqual({tuple(row) for row in self.spark.table(name).collect()},
                                 {(10, 1), (20, 2), (40, None)})
                self.assert_row_statistics(name, 3)
                self.assertEqual({row[0] for row in self.spark.sql(
                    'SHOW PARTITIONS `' + name + '`').collect()},
                    {column + '=1', column + '=2', column + '=__HIVE_DEFAULT_PARTITION__'})
        self.assertEqual(self.spark.table('customer').count(), 2)
        self.assert_row_statistics('customer', 2)
        self.assertEqual(self.spark.table('date_dim').count(), 3)

    def test_cutoff_without_analysis_still_uses_temporary_views(self):
        driver.setup_tables(self.spark, str(self.root), 'parquet', False, [],
                            cutoff_date=datetime.date(2001, 1, 2))
        for name in driver.DATE_PARTITION_COLUMNS:
            with self.subTest(table=name):
                self.assertTrue(self.spark.catalog.getTable(name).isTemporary)
                self.assertEqual(self.spark.table(name).count(), 3)
        self.assertEqual(self.spark.table('customer').count(), 2)

    def test_existing_table_is_not_reused_or_changed_by_cutoff_analysis(self):
        driver._create_data_source_table(self.spark, 'store_sales',
                                         str(self.root / 'store_sales'), 'parquet')
        qualified = self.spark.catalog.currentDatabase() + '.store_sales'
        before = {tuple(row) for row in self.spark.table(qualified).collect()}
        for shadowed in (False, True):
            with self.subTest(temporary_view=shadowed):
                if shadowed:
                    self.spark.table(qualified).createOrReplaceTempView('store_sales')
                with self.assertRaisesRegex(ValueError, 'fresh catalog table: store_sales'):
                    driver.setup_tables(self.spark, str(self.root), 'parquet', False, [],
                                        analyze_tables=True, cutoff_date=datetime.date(2001, 1, 2))
                self.assertEqual({tuple(row) for row in self.spark.table(qualified).collect()}, before)
        self.assertEqual(len(before), 4)


if __name__ == '__main__':
    unittest.main()
