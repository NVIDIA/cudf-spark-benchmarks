# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Exercise custom dataset metadata and cutoff loading with tiny Parquet tables."""

import contextlib
import datetime
import io
import json
from pathlib import Path
import tempfile
import sys
import unittest

from pyspark.sql import SparkSession
from pyspark.sql.types import DateType, IntegerType, StructField, StructType

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power


class ManifestTableTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('manifest-table-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        cls.tables = {'date_dim': {'date_partition_column': None},
                      'orders': {'date_partition_column': 'order_day'},
                      'events': {'date_partition_column': 'event_day'},
                      'customers': {'date_partition_column': None}}
        cls.manifest = cls.root / '_benchmark_manifest.json'
        cls.manifest.write_text(json.dumps({'tables': cls.tables,
                                            'parameters': {'seed': 7}}))
        schema = StructType([StructField('d_date_sk', IntegerType()),
                             StructField('d_date', DateType())])
        cls.spark.createDataFrame(
            [(key, datetime.date(1998, 1, key)) for key in (1, 2, 3)],
            schema).coalesce(1).write.parquet(str(cls.root / 'date_dim'))
        for name, column in (('orders', 'order_day'), ('events', 'event_day')):
            schema = StructType([StructField('payload', IntegerType()),
                                 StructField(column, IntegerType())])
            cls.spark.createDataFrame([(1, 1), (2, 2), (3, 3), (0, None)],
                                      schema).coalesce(1).write.partitionBy(column).parquet(
                                          str(cls.root / name))
        cls.spark.createDataFrame([(7,), (8,)], 'customer_id int').coalesce(1).write.parquet(
            str(cls.root / 'customers'))
        cls.spark.createDataFrame([(9,)], 'ignored_id int').coalesce(1).write.parquet(
            str(cls.root / 'unlisted'))

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_run_stream_loads_listed_tables_and_inclusive_custom_partitions(self):
        with contextlib.redirect_stdout(io.StringIO()):
            nds_power.run_query_stream(
                str(self.root), None, {}, str(self.root / 'times.csv'),
                None, None, None, 0, 0, None, keep_sc=True,
                json_summary_folder=str(self.root / 'summaries'), cutoff_date='1998-01-02')
        self.assertEqual({table.name for table in self.spark.catalog.listTables()}, set(self.tables))
        for name, column in (('orders', 'order_day'), ('events', 'event_day')):
            self.assertEqual({row[0] for row in self.spark.table(name).select(column).collect()},
                             {1, 2, None})
            self.assertEqual(len(self.spark.table(name).inputFiles()), 3)
        self.assertEqual({row[0] for row in self.spark.table('customers').collect()}, {7, 8})
        self.assertEqual(self.spark.table('date_dim').count(), 3)
        self.assertTrue((self.root / 'times.csv').is_file())

    def test_custom_cutoff_catalog_collects_statistics_only_for_listed_tables(self):
        self.spark.sql('CREATE DATABASE manifest_statistics')
        self.spark.catalog.setCurrentDatabase('manifest_statistics')
        try:
            names, columns = nds_power._manifest_tables(self.spark, str(self.root), 'parquet')
            nds_power.setup_tables(
                self.spark, str(self.root), 'parquet', False, [],
                cutoff_date=datetime.date(1998, 1, 2), analyze='all_columns',
                table_names=names, date_partition_columns=columns)
            report = nds_power.analyze_catalog(self.spark, 'all_columns', names, None)
            self.assertEqual({entry['table'] for entry in report['tables']}, set(self.tables))
            self.assertEqual({table.name for table in self.spark.catalog.listTables()}, set(self.tables))
            for name in ('orders', 'events'):
                self.assertEqual(self.spark.table(name).count(), 3)
                statistics = [row[1] for row in self.spark.sql(
                    'DESCRIBE EXTENDED ' + name).collect() if row[0] == 'Statistics']
                self.assertEqual(len(statistics), 1)
                self.assertRegex(statistics[0], r'\b3 rows\b')
        finally:
            self.spark.catalog.setCurrentDatabase('default')
            self.spark.sql('DROP DATABASE manifest_statistics CASCADE')

    def test_custom_cutoff_legacy_analysis_uses_selected_rows(self):
        self.spark.sql('CREATE DATABASE manifest_legacy_statistics')
        self.spark.catalog.setCurrentDatabase('manifest_legacy_statistics')
        try:
            names, columns = nds_power._manifest_tables(self.spark, str(self.root), 'parquet')
            nds_power.setup_tables(
                self.spark, str(self.root), 'parquet', False, [],
                analyze_tables=True, cutoff_date=datetime.date(1998, 1, 2),
                table_names=names, date_partition_columns=columns)
            self.assertEqual({table.name for table in self.spark.catalog.listTables()}, set(self.tables))
            for name in ('orders', 'events'):
                self.assertEqual({row[0] for row in self.spark.table(name).select('payload').collect()},
                                 {0, 1, 2})
                statistics = [row[1] for row in self.spark.sql(
                    'DESCRIBE EXTENDED ' + name).collect() if row[0] == 'Statistics']
                self.assertEqual(len(statistics), 1)
                self.assertRegex(statistics[0], r'\b3 rows\b')
            self.assertEqual(self.spark.table('customers').count(), 2)
        finally:
            self.spark.catalog.setCurrentDatabase('default')
            self.spark.sql('DROP DATABASE manifest_legacy_statistics CASCADE')

    def test_manifest_absence_leaves_default_selection_available(self):
        self.assertIsNone(nds_power._manifest_tables(
            self.spark, str(self.root / 'absent'), 'parquet'))

    def test_manifest_requires_parquet_and_date_dim(self):
        with self.assertRaisesRegex(ValueError, 'requires Parquet'):
            nds_power._manifest_tables(self.spark, str(self.root), 'orc')
        self.manifest.write_text(json.dumps({'tables': {'orders': self.tables['orders']}}))
        try:
            with self.assertRaisesRegex(ValueError, 'must list date_dim'):
                nds_power._manifest_tables(self.spark, str(self.root), 'parquet')
        finally:
            self.manifest.write_text(json.dumps({'tables': self.tables}))


if __name__ == '__main__':
    unittest.main()
