# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Keep Spark partition values and rows identical with declared or discovered layouts."""

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


class ManifestPartitionLayoutTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('manifest-partition-layout-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        table = cls.root / 'events'
        cls.spark.createDataFrame(
            [(1, 'east', datetime.date(2001, 1, 1), 'a'),
             (2, 'east', datetime.date(2001, 1, 3), 'b')],
            'payload int, region string, event_day date, _tenant string').coalesce(1) \
            .write.partitionBy('region', 'event_day', '_tenant').parquet(str(table))
        # External tools can percent-encode UTF-8, unlike Spark's bytewise path escaping.
        (table / 'region=east').rename(table / 'region=%C3%A9')
        (table / 'region=empty').mkdir()
        (table / 'region=%C3%A9' / 'event_day=2001-01-02').mkdir()

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_views_and_analyzed_tables_match_spark_with_empty_and_escaped_partitions(self):
        source = self.spark.read.parquet(str(self.root / 'events'))
        expected = {tuple(row) for row in source.where("event_day <= DATE '2001-01-02'").collect()}
        self.assertEqual(expected, {(1, 'Ã©', datetime.date(2001, 1, 1), 'a')})
        for declared in (False, True):
            for analyze in (None, 'table'):
                with self.subTest(declared=declared, analyze=analyze):
                    database = 'layout_' + str(declared).lower() + '_' + (analyze or 'views')
                    self.spark.sql('CREATE DATABASE ' + database)
                    self.spark.catalog.setCurrentDatabase(database)
                    try:
                        metadata = {'date_partition_column': 'event_day'}
                        if declared:
                            metadata['partition_columns'] = ['region', 'event_day', '_tenant']
                        manifest = self.root / 'manifest.json'
                        manifest.write_text(json.dumps({'tables': {'events': metadata}}))
                        tables = nds_power._dataset_tables(
                            str(self.root), 'parquet', False,
                            nds_power._manifest_tables(self.spark, str(manifest)))
                        with contextlib.redirect_stdout(io.StringIO()):
                            nds_power.setup_tables(
                                self.spark, str(self.root), 'parquet', False, [],
                                cutoff_date=datetime.date(2001, 1, 2), analyze=analyze, tables=tables)
                            if analyze:
                                nds_power.analyze_catalog(self.spark, analyze, tables, None)
                        self.assertEqual({tuple(row) for row in self.spark.table('events').collect()},
                                         expected)
                    finally:
                        self.spark.catalog.dropTempView('events')
                        self.spark.catalog.setCurrentDatabase('default')
                        self.spark.sql('DROP DATABASE ' + database + ' CASCADE')


    def test_incomplete_partition_declaration_is_rejected_before_catalog_registration(self):
        tables = nds_power._dataset_tables(
            str(self.root), 'parquet', False,
            {'events': {'date_partition_column': 'event_day',
                        'partition_columns': ['region', 'event_day']}})
        for mode in (None, 'table'):
            with self.subTest(analyze=mode), self.assertRaisesRegex(
                    ValueError, 'Unexpected partition directory layout'):
                with contextlib.redirect_stdout(io.StringIO()):
                    nds_power.setup_tables(
                        self.spark, str(self.root), 'parquet', False, [],
                        cutoff_date=datetime.date(2001, 1, 2), analyze=mode, tables=tables)

    def test_empty_stray_folders_beneath_partition_leaves_do_not_change_selected_rows(self):
        day = datetime.date(2001, 1, 1)
        expected = {(1, day), (3, None)}
        path = self.root / 'nested_events'
        self.spark.createDataFrame(
            [(1, day), (2, datetime.date(2001, 1, 3)), (3, None)], 'payload int, day date') \
            .coalesce(1).write.partitionBy('day').parquet(str(path))
        for partition in path.glob('day=*'):
            (partition / 'extra' / 'deeper').mkdir(parents=True)
        original = self.spark.conf.get('spark.sql.sources.useV1SourceList')
        try:
            for sources in ('parquet', ''):
                self.spark.conf.set('spark.sql.sources.useV1SourceList', sources)
                for declared in (False, True):
                    for analyze in (None, 'table'):
                        with self.subTest(sources=sources, declared=declared, analyze=analyze):
                            metadata = {'date_partition_column': 'day'}
                            if declared:
                                metadata['partition_columns'] = ['day']
                            tables = nds_power._dataset_tables(
                                str(self.root), 'parquet', False, {'nested_events': metadata})
                            try:
                                with contextlib.redirect_stdout(io.StringIO()):
                                    nds_power.setup_tables(
                                        self.spark, str(self.root), 'parquet', False, [],
                                        cutoff_date=day, analyze=analyze, tables=tables)
                                    if analyze:
                                        nds_power.analyze_catalog(self.spark, analyze, tables, None)
                                self.assertEqual(
                                    {tuple(row) for row in self.spark.table('nested_events').collect()},
                                    expected)
                            finally:
                                self.spark.catalog.dropTempView('nested_events')
                                self.spark.sql('DROP TABLE IF EXISTS nested_events')
        finally:
            self.spark.conf.set('spark.sql.sources.useV1SourceList', original)

    def test_empty_nested_dated_directory_does_not_make_null_only_data_valid(self):
        path = self.root / 'null_only_nested'
        self.spark.createDataFrame([(1, None)], 'payload int, day date').coalesce(1) \
            .write.partitionBy('day').parquet(str(path))
        (path / 'day=2001-01-01' / 'extra' / 'deeper').mkdir(parents=True)
        original = self.spark.conf.get('spark.sql.sources.useV1SourceList')
        try:
            for sources in ('parquet', ''):
                self.spark.conf.set('spark.sql.sources.useV1SourceList', sources)
                for declared in (False, True):
                    for analyze in (None, 'table'):
                        with self.subTest(sources=sources, declared=declared, analyze=analyze):
                            metadata = {'date_partition_column': 'day'}
                            if declared:
                                metadata['partition_columns'] = ['day']
                            tables = nds_power._dataset_tables(
                                str(self.root), 'parquet', False, {'null_only_nested': metadata})
                            try:
                                with contextlib.redirect_stdout(io.StringIO()), self.assertRaisesRegex(
                                        ValueError, 'No dated data files.*null_only_nested'):
                                    nds_power.setup_tables(
                                        self.spark, str(self.root), 'parquet', False, [],
                                        cutoff_date=datetime.date(2001, 1, 1), analyze=analyze,
                                        tables=tables)
                                self.assertFalse(nds_power.catalog_table_exists(
                                    self.spark, 'null_only_nested'))
                            finally:
                                self.spark.catalog.dropTempView('null_only_nested')
                                self.spark.sql('DROP TABLE IF EXISTS null_only_nested')
        finally:
            self.spark.conf.set('spark.sql.sources.useV1SourceList', original)


if __name__ == '__main__':
    unittest.main()
