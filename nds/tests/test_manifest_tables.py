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
                str(self.root), None,
                {'query1': 'SELECT o.payload FROM orders o JOIN events e '
                           'ON o.payload = e.payload'},
                str(self.root / 'times.csv'), None, None, None, 0, 1, None,
                output_path=str(self.root / 'output'), keep_sc=True,
                json_summary_folder=str(self.root / 'summaries'), cutoff_date='1998-01-02',
                dataset_manifest=str(self.manifest))
        self.assertEqual({table.name for table in self.spark.catalog.listTables()}, set(self.tables))
        for name, column in (('orders', 'order_day'), ('events', 'event_day')):
            self.assertEqual({row[0] for row in self.spark.table(name).select(column).collect()},
                             {1, 2, None})
            self.assertEqual(len(self.spark.table(name).inputFiles()), 3)
        self.assertEqual({row[0] for row in self.spark.table('customers').collect()}, {7, 8})
        self.assertEqual(self.spark.table('date_dim').count(), 3)
        self.assertTrue((self.root / 'times.csv').is_file())
        rows = self.spark.read.parquet(str(self.root / 'output' / 'query1')).collect()
        self.assertEqual({row.payload for row in rows}, {0, 1, 2})

    def test_custom_cutoff_catalog_collects_statistics_only_for_listed_tables(self):
        self.spark.sql('CREATE DATABASE manifest_statistics')
        self.spark.catalog.setCurrentDatabase('manifest_statistics')
        try:
            tables = nds_power._dataset_tables(
                str(self.root), 'parquet', False,
                nds_power._manifest_tables(self.spark, str(self.manifest)))
            nds_power.setup_tables(
                self.spark, str(self.root), 'parquet', False, [],
                cutoff_date=datetime.date(1998, 1, 2), analyze='all_columns',
                tables=tables)
            report = nds_power.analyze_catalog(self.spark, 'all_columns', tables, None)
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
            tables = nds_power._dataset_tables(
                str(self.root), 'parquet', False,
                nds_power._manifest_tables(self.spark, str(self.manifest)))
            nds_power.setup_tables(
                self.spark, str(self.root), 'parquet', False, [],
                analyze_tables=True, cutoff_date=datetime.date(1998, 1, 2),
                tables=tables)
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

    def test_explicit_file_uri_reads_the_same_manifest_as_a_local_path(self):
        self.assertEqual(nds_power._manifest_tables(self.spark, self.manifest.as_uri()),
                         nds_power._manifest_tables(self.spark, str(self.manifest)))

    def test_decimal_date_dim_keys_resolve_selected_partitions(self):
        with tempfile.TemporaryDirectory() as directory:
            self.spark.createDataFrame(
                [(1, datetime.date(1998, 1, 1)), (2, datetime.date(1998, 1, 2)),
                 (3, datetime.date(1998, 1, 3))], 'key int, d_date date') \
                .selectExpr('CAST(key AS DECIMAL(10, 0)) AS d_date_sk', 'd_date') \
                .write.parquet(str(Path(directory) / 'date_dim'))
            dates = nds_power._date_key_mapping(self.spark, directory, 'parquet', False)
            selected = nds_power._partitions_at_cutoff(
                self.spark, str(self.root / 'orders'), 'order_day', lambda: dates,
                datetime.date(1998, 1, 2), ['order_day'])
            self.assertEqual({spec['order_day'] for spec, _ in selected},
                             {'1', '2', '__HIVE_DEFAULT_PARTITION__'})

    def test_integer_cutoffs_require_date_dim_in_the_manifest(self):
        self.manifest.write_text(json.dumps({'tables': {'orders': self.tables['orders']}}))
        try:
            self.assertEqual(nds_power._manifest_tables(self.spark, str(self.manifest)),
                             {'orders': {'date_partition_column': 'order_day'}})
            with self.assertRaisesRegex(ValueError, 'Integer date partitions require date_dim'):
                nds_power.setup_tables(
                    self.spark, str(self.root), 'parquet', False, [],
                    tables=nds_power._dataset_tables(
                        str(self.root), 'parquet', False,
                        {'orders': {'date_partition_column': 'order_day'}}),
                    cutoff_date=datetime.date(1998, 1, 2))
        finally:
            self.manifest.write_text(json.dumps({'tables': self.tables}))



class GenericDatasetTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('generic-dataset-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        (cls.root / '_benchmark_manifest.json').write_text(json.dumps({
            'tables': {'purchases': {}, 'accounts': {'date_partition_column': None}}}))
        cls.spark.createDataFrame([(1, 10), (2, 20), (3, 10)],
                                  'purchase_id int, account_id int').coalesce(1).write.parquet(
                                      str(cls.root / 'purchases'))
        cls.spark.createDataFrame([(10, 'retail'), (20, 'business')],
                                  'account_id int, category string').coalesce(1).write.parquet(
                                      str(cls.root / 'accounts'))
        cls.spark.createDataFrame([(99,)], 'ignored_id int').coalesce(1).write.parquet(
            str(cls.root / 'unlisted'))
        cls.dated = cls.root / 'dated'
        cls.dated.mkdir()
        (cls.dated / '_benchmark_manifest.json').write_text(json.dumps({
            'tables': {'purchases': {'date_partition_column': 'purchase_date'}, 'accounts': {}}}))
        cls.spark.createDataFrame(
            [(1, 10, datetime.date(2001, 7, 1)), (2, 20, datetime.date(2001, 7, 2)),
             (3, 10, datetime.date(2001, 7, 3)), (4, 20, None)],
            'purchase_id int, account_id int, purchase_date date').coalesce(1) \
            .write.partitionBy('purchase_date').parquet(str(cls.dated / 'purchases'))
        cls.spark.read.parquet(str(cls.root / 'accounts')).write.parquet(str(cls.dated / 'accounts'))

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_custom_join_without_date_dim_runs_with_views_or_analyzed_tables(self):
        for mode in (None, 'table', 'all_columns'):
            with self.subTest(analyze=mode):
                database = 'generic_' + (mode or 'views')
                self.spark.sql('CREATE DATABASE ' + database)
                self.spark.catalog.setCurrentDatabase(database)
                run = self.root / database
                run.mkdir()
                try:
                    with contextlib.redirect_stdout(io.StringIO()):
                        nds_power.run_query_stream(
                            str(self.root), None,
                            {'query1': 'SELECT p.purchase_id, a.category FROM purchases p '
                                       'JOIN accounts a ON p.account_id = a.account_id'},
                            str(run / 'times.csv'), None, None, None, 0, 1, None,
                            output_path=str(run / 'output'), keep_sc=True, analyze=mode,
                            json_summary_folder=str(run / 'summaries'),
                            dataset_manifest=(self.root / '_benchmark_manifest.json').as_uri()
                            if mode == 'table' else str(self.root / '_benchmark_manifest.json'))
                    tables = {table.name: table.isTemporary
                              for table in self.spark.catalog.listTables()}
                    self.assertEqual(tables, {'purchases': mode is None, 'accounts': mode is None})
                    rows = self.spark.read.parquet(str(run / 'output' / 'query1')).collect()
                    self.assertEqual({tuple(row) for row in rows},
                                     {(1, 'retail'), (2, 'business'), (3, 'retail')})
                    cost = run / 'summaries' / 'statistics' / 'analyze-cost.json'
                    if mode is None:
                        self.assertFalse(cost.exists())
                    else:
                        report = json.loads(cost.read_text())
                        self.assertEqual(report['mode'], mode)
                        self.assertEqual({entry['table'] for entry in report['tables']},
                                         {'purchases', 'accounts'})
                finally:
                    for table in ('purchases', 'accounts'):
                        self.spark.catalog.dropTempView(table)
                    self.spark.catalog.setCurrentDatabase('default')
                    self.spark.sql('DROP DATABASE ' + database + ' CASCADE')


    def test_date_partition_cutoff_without_date_dim_selects_complete_days_and_nulls(self):
        for mode in (None, 'table', 'all_columns'):
            with self.subTest(analyze=mode):
                database = 'dated_' + (mode or 'views')
                self.spark.sql('CREATE DATABASE ' + database)
                self.spark.catalog.setCurrentDatabase(database)
                run = self.root / database
                run.mkdir()
                try:
                    with contextlib.redirect_stdout(io.StringIO()):
                        nds_power.run_query_stream(
                            str(self.dated), None,
                            {'query1': 'SELECT p.purchase_id, a.category FROM purchases p '
                                       'JOIN accounts a ON p.account_id = a.account_id'},
                            str(run / 'times.csv'), None, None, None, 0, 1, None,
                            output_path=str(run / 'output'), keep_sc=True, analyze=mode,
                            cutoff_date='2001-07-02', json_summary_folder=str(run / 'summaries'),
                            dataset_manifest=str(self.dated / '_benchmark_manifest.json'))
                    tables = {table.name: table.isTemporary
                              for table in self.spark.catalog.listTables()}
                    self.assertEqual(tables, {'purchases': mode is None, 'accounts': mode is None})
                    selected = self.spark.table('purchases').collect()
                    self.assertEqual({row.purchase_date for row in selected},
                                     {datetime.date(2001, 7, 1), datetime.date(2001, 7, 2), None})
                    self.assertEqual(self.spark.table('accounts').count(), 2)
                    rows = self.spark.read.parquet(str(run / 'output' / 'query1')).collect()
                    self.assertEqual({tuple(row) for row in rows},
                                     {(1, 'retail'), (2, 'business'), (4, 'business')})
                    if mode is not None:
                        statistics = [row[1] for row in self.spark.sql(
                            'DESCRIBE EXTENDED purchases').collect() if row[0] == 'Statistics']
                        self.assertEqual(len(statistics), 1)
                        self.assertRegex(statistics[0], r'\b3 rows\b')
                        cost = run / 'summaries' / 'statistics' / 'analyze-cost.json'
                        report = json.loads(cost.read_text())
                        self.assertEqual({entry['table'] for entry in report['tables']},
                                         {'purchases', 'accounts'})
                finally:
                    for table in ('purchases', 'accounts'):
                        self.spark.catalog.dropTempView(table)
                    self.spark.catalog.setCurrentDatabase('default')
                    self.spark.sql('DROP DATABASE ' + database + ' CASCADE')


if __name__ == '__main__':
    unittest.main()
