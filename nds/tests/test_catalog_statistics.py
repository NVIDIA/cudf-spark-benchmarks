# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Spark-submit tests of selected catalog inputs and recomputed column statistics."""

import datetime
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power
from benchmark_statistics import analyze_catalog


sys.path.insert(0, str(ROOT / 'nds-h'))
spec = importlib.util.spec_from_file_location('nds_h_power', ROOT / 'nds-h/nds_h_power.py')
nds_h_power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nds_h_power)


class CatalogStatisticsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        spark = cls.builder().appName('statistics-fixtures').getOrCreate()
        spark.sparkContext.setLogLevel('ERROR')
        try:
            for name in nds_power.get_schemas(False):
                target = str(cls.root / 'nds' / name)
                if name == 'date_dim':
                    spark.createDataFrame(
                        [(key, datetime.date(2001, 1, key)) for key in (1, 2, 3)],
                        'd_date_sk int, d_date date').coalesce(1).write.parquet(target)
                elif name in nds_power.DATE_PARTITION_COLUMNS:
                    column = nds_power.DATE_PARTITION_COLUMNS[name]
                    spark.createDataFrame(
                        [(10, 1), (20, 2), (30, 3), (40, None)],
                        'payload int, ' + column + ' int').coalesce(1).write.partitionBy(
                            column).parquet(target)
                else:
                    spark.createDataFrame([(1,), (2,)], 'payload int').coalesce(1).write.parquet(target)
            for name in nds_h_power.get_schemas():
                spark.createDataFrame([(1,), (2,), (None,)], 'payload int').coalesce(1).write.parquet(
                    str(cls.root / 'ndsh' / name))
        finally:
            spark.stop()

    @classmethod
    def builder(cls):
        return (SparkSession.builder.master('local[2]')
                .config('spark.ui.enabled', 'false')
                .config('spark.sql.shuffle.partitions', '1')
                .config('spark.sql.catalogImplementation', 'in-memory')
                .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                .config('spark.sql.hive.manageFilesourcePartitions', 'true'))

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def start_session(self):
        session = self.builder().appName('catalog-statistics-tests').getOrCreate()
        session.sparkContext.setLogLevel('ERROR')
        session.sql('CREATE DATABASE IF NOT EXISTS caller_catalog')
        session.catalog.setCurrentDatabase('caller_catalog')
        for table in list(nds_power.get_schemas(False)) + list(nds_h_power.get_schemas()):
            session.catalog.dropTempView(table)
            session.sql('DROP TABLE IF EXISTS `' + table + '`')
        return session

    def assert_row_statistics(self, session, table, count):
        rows = session.sql('DESCRIBE EXTENDED ' + table).collect()
        statistics = [row[1] for row in rows if row[0] == 'Statistics']
        self.assertEqual(len(statistics), 1)
        self.assertRegex(statistics[0], r'\b' + str(count) + r' rows\b')

    def test_cutoff_column_statistics_cover_only_selected_partitions_and_recompute(self):
        databases = []
        for day, count in ((2, 3), (3, 4)):
            with self.subTest(day=day):
                session = self.start_session()
                try:
                    databases.append(session.catalog.currentDatabase())
                    warehouse = session.conf.get('spark.sql.warehouse.dir')
                    nds_power.setup_tables(session, str(self.root / 'nds'), 'parquet', False, [],
                                           cutoff_date=datetime.date(2001, 1, day), analyze='all_columns')
                    report_folder = self.root / ('summary-' + str(day))
                    report = analyze_catalog(session, 'all_columns', nds_power.get_schemas(False),
                                             str(report_folder))
                    self.assertEqual(report['mode'], 'all_columns')
                    self.assertEqual(session.catalog.currentDatabase(), 'caller_catalog')
                    self.assertEqual(session.conf.get('spark.sql.catalogImplementation'), 'in-memory')
                    self.assertEqual(session.conf.get('spark.sql.warehouse.dir'),
                                     warehouse)
                    self.assertEqual(len(report['tables']), 24)
                    self.assertGreater(report['duration_ms'], 0)
                    self.assertEqual(json.loads(
                        (report_folder / 'statistics/analyze-cost.json').read_text()), report)
                    for table, column in nds_power.DATE_PARTITION_COLUMNS.items():
                        with self.subTest(table=table):
                            self.assertEqual(session.table(table).count(), count)
                            self.assert_row_statistics(session, table, count)
                            partitions = {row[0] for row in session.sql(
                                'SHOW PARTITIONS ' + table).collect()}
                            self.assertEqual(partitions, {
                                column + '=' + str(key) for key in range(1, day + 1)
                            } | {column + '=__HIVE_DEFAULT_PARTITION__'})
                            values = dict(tuple(row) for row in session.sql(
                                'DESCRIBE EXTENDED ' + table + ' ' + column).collect())
                            self.assertEqual(values['max'], str(day))
                            self.assertEqual(values['num_nulls'], '1')
                    self.assertEqual(session.table('customer').count(), 2)
                    self.assert_row_statistics(session, 'customer', 2)
                finally:
                    session.stop()
        self.assertEqual(databases, ['caller_catalog', 'caller_catalog'])

    def test_full_inputs_none_and_table_modes_and_ndsh_column_statistics(self):
        for mode in (None, 'none', 'table'):
            with self.subTest(mode=mode):
                session = self.start_session()
                try:
                    nds_power.setup_tables(session, str(self.root / 'nds'), 'parquet', False, [],
                                           analyze=mode)
                    report = analyze_catalog(session, mode, nds_power.get_schemas(False),
                                             str(self.root / ('full-' + str(mode))))
                    self.assertEqual(session.table('store_sales').count(), 4)
                    self.assertEqual(session.catalog.getTable('store_sales').isTemporary,
                                     mode in (None, 'none'))
                    self.assertEqual(session.catalog.currentDatabase(), 'caller_catalog')
                    if mode in (None, 'none'):
                        self.assertFalse((self.root / ('full-' + str(mode)) / 'statistics').exists())
                        self.assertEqual(report['duration_ms'], 0)
                        self.assertEqual(report['tables'], [])
                    else:
                        self.assert_row_statistics(session, 'store_sales', 4)
                finally:
                    session.stop()
        session = self.start_session()
        try:
            nds_h_power.setup_tables(session, str(self.root / 'ndsh'), 'parquet', [], analyze='all_columns')
            analyze_catalog(session, 'all_columns', nds_h_power.get_schemas(),
                            str(self.root / 'ndsh-summary'))
            for table in nds_h_power.get_schemas():
                self.assertEqual(session.table(table).count(), 3)
                self.assert_row_statistics(session, table, 3)
                values = dict(tuple(row) for row in session.sql(
                    'DESCRIBE EXTENDED ' + table + ' payload').collect())
                self.assertEqual(values['num_nulls'], '1')
        finally:
            session.stop()


if __name__ == '__main__':
    unittest.main()
