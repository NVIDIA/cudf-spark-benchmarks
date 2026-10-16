# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Exercise cutoff selection across multiple directory partition columns."""

import contextlib
import datetime
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power


class MultilevelCutoffTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('multilevel-cutoff-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        cls.spark.createDataFrame(
            [(key, datetime.date(2001, 7, key)) for key in (1, 2, 3)],
            'd_date_sk int, d_date date').coalesce(1).write.parquet(str(cls.root / 'date_dim'))
        cls.definitions = {'date_dim': {}}
        cls.expected = {}
        rows = [(1, 'north', 1), (2, 'south', 2), (3, 'north', 3),
                (4, 'south', None), (5, 'south', 1), (6, 'south', 3), (7, None, 2)]
        for kind in ('date', 'key'):
            values = [(payload, region, datetime.date(2001, 7, day)
                       if kind == 'date' and day is not None else day)
                      for payload, region, day in rows]
            for position, columns in (('first', ('event_day', 'region')),
                                      ('second', ('region', 'event_day'))):
                table = kind + '_' + position
                cls.spark.createDataFrame(
                    values, 'payload int, region string, event_day ' +
                    ('date' if kind == 'date' else 'int')).coalesce(1) \
                    .write.partitionBy(*columns).parquet(str(cls.root / table))
                cls.definitions[table] = {'date_partition_column': 'event_day'}
                cls.expected[table] = {row for row in values if row[0] not in (3, 6)}
        cls.manifest = cls.root / 'workload.json'
        cls.manifest.write_text(json.dumps({'tables': cls.definitions}))

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_cutoff_preserves_other_partitions_with_views_and_analyzed_tables(self):
        for mode in (None, 'table', 'all_columns'):
            with self.subTest(analyze=mode):
                database = 'multilevel_' + (mode or 'views')
                self.spark.sql('CREATE DATABASE ' + database)
                self.spark.catalog.setCurrentDatabase(database)
                try:
                    tables = nds_power._dataset_tables(
                        str(self.root), 'parquet', False,
                        nds_power._manifest_tables(self.spark, str(self.manifest)))
                    with contextlib.redirect_stdout(io.StringIO()):
                        nds_power.setup_tables(
                            self.spark, str(self.root), 'parquet', False, [],
                            cutoff_date=datetime.date(2001, 7, 2), analyze=mode, tables=tables)
                        if mode is not None:
                            report = nds_power.analyze_catalog(self.spark, mode, tables, None)
                            self.assertEqual({entry['table'] for entry in report['tables']},
                                             set(self.definitions))
                    for table, expected in self.expected.items():
                        with self.subTest(table=table):
                            rows = self.spark.table(table).select(
                                'payload', 'region', 'event_day').collect()
                            self.assertEqual({tuple(row) for row in rows}, expected)
                            self.assertEqual(self.spark.catalog.getTable(table).isTemporary,
                                             mode is None)
                            if mode is not None:
                                statistics = [row[1] for row in self.spark.sql(
                                    'DESCRIBE EXTENDED ' + table).collect()
                                    if row[0] == 'Statistics']
                                self.assertEqual(len(statistics), 1)
                                self.assertRegex(statistics[0], r'\b5 rows\b')
                            if mode == 'all_columns':
                                column = dict((row[0], row[1]) for row in self.spark.sql(
                                    'DESCRIBE EXTENDED ' + table + ' event_day').collect())
                                self.assertEqual(column['distinct_count'], '2')
                                self.assertEqual(column['num_nulls'], '1')
                    self.assertEqual(self.spark.table('date_dim').count(), 3)
                finally:
                    for table in self.definitions:
                        self.spark.catalog.dropTempView(table)
                    self.spark.catalog.setCurrentDatabase('default')
                    self.spark.sql('DROP DATABASE ' + database + ' CASCADE')


if __name__ == '__main__':
    unittest.main()
