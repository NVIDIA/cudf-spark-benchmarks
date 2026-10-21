# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Validate declared directory layouts using Spark's cached partition metadata."""

import datetime
from pathlib import Path
import sys
import tempfile
import unittest

from pyspark.sql import SparkSession

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power


class PartitionMetadataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[2]').appName('partition-metadata-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.shuffle.partitions', '1')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')

    @classmethod
    def tearDownClass(cls):
        cls.spark.stop()
        cls.directory.cleanup()

    def test_declared_partition_layout_matches_spark_discovered_columns(self):
        path = self.root / 'declared_layout'
        self.spark.createDataFrame([(1, datetime.date(2001, 7, 1), 'west')],
                                   'payload int, day date, region string').coalesce(1) \
            .write.partitionBy('day', 'region').parquet(str(path))
        original = self.spark.conf.get('spark.sql.sources.useV1SourceList')
        try:
            for sources in ('parquet', ''):
                with self.subTest(sources=sources):
                    self.spark.conf.set('spark.sql.sources.useV1SourceList', sources)
                    frame = self.spark.read.parquet(str(path))
                    nds_power._require_partition_files(
                        self.spark, frame, ['day', 'region'], 'day', str(path))
                    with self.assertRaisesRegex(ValueError, 'Unexpected partition directory layout'):
                        nds_power._require_partition_files(
                            self.spark, frame, ['day'], 'day', str(path))
                    with self.assertRaisesRegex(ValueError, 'Unexpected partition directory layout'):
                        nds_power._require_partition_files(
                            self.spark, frame, ['region', 'day'], 'day', str(path))
        finally:
            self.spark.conf.set('spark.sql.sources.useV1SourceList', original)

    def test_empty_dated_directory_does_not_make_null_only_data_valid(self):
        path = self.root / 'null_only_declared_layout'
        self.spark.createDataFrame([(1, None)], 'payload int, day date').coalesce(1) \
            .write.partitionBy('day').parquet(str(path))
        (path / 'day=2001-07-01').mkdir()
        selected = nds_power._partitions_at_cutoff(
            self.spark, str(path), 'day', lambda: {}, datetime.date(2001, 7, 1), ['day'])
        original = self.spark.conf.get('spark.sql.sources.useV1SourceList')
        try:
            for sources in ('parquet', ''):
                with self.subTest(sources=sources):
                    self.spark.conf.set('spark.sql.sources.useV1SourceList', sources)
                    frame = self.spark.read.option('basePath', str(path)).parquet(
                        *[directory for _, directory in selected])
                    with self.assertRaisesRegex(ValueError, 'No dated data files.*null_only_declared_layout'):
                        nds_power._require_partition_files(
                            self.spark, frame, ['day'], 'day', str(path))
        finally:
            self.spark.conf.set('spark.sql.sources.useV1SourceList', original)


if __name__ == '__main__':
    unittest.main()
