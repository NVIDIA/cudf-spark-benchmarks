# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check existing catalog inputs, summary reuse, and exported analysis timings."""

import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from uuid import uuid4

from pyspark.sql import SparkSession
from pyspark.sql.types import IntegerType, StructField, StructType

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power
import benchmark_statistics

sys.path.insert(0, str(ROOT / 'nds-h'))
spec = importlib.util.spec_from_file_location('nds_h_reuse', ROOT / 'nds-h/nds_h_power.py')
nds_h_power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nds_h_power)


class AnalysisReuseTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cls.spark = (SparkSession.builder.master('local[1]').appName('analysis-reuse-tests')
                     .config('spark.ui.enabled', 'false')
                     .config('spark.sql.catalogImplementation', 'in-memory')
                     .config('spark.sql.warehouse.dir', str(cls.root / 'warehouse'))
                     .getOrCreate())
        cls.spark.sparkContext.setLogLevel('ERROR')
        cls.database = 'analysis_reuse_' + uuid4().hex
        cls.spark.sql('CREATE DATABASE ' + cls.database)
        cls.spark.catalog.setCurrentDatabase(cls.database)
        cls.spark.createDataFrame([(111,)], 'payload int').write.parquet(str(cls.root / 'old'))
        for name in ('fresh', 'facts'):
            cls.spark.createDataFrame([(222,), (333,)], 'payload int').write.parquet(
                str(cls.root / 'inputs' / name))
        cls.schema = StructType([StructField('payload', IntegerType())])

    @classmethod
    def tearDownClass(cls):
        cls.spark.sql('DROP DATABASE ' + cls.database + ' CASCADE')
        cls.spark.stop()
        cls.directory.cleanup()

    def tearDown(self):
        for name in ('fresh', 'facts'):
            self.spark.catalog.dropTempView(name)
            self.spark.sql('DROP TABLE IF EXISTS `' + name + '`')

    def options(self, directory):
        return dict(input_prefix=str(self.root / 'inputs'), property_file=None, query_dict={},
                    time_log_output_path=str(directory / 'times.csv'),
                    extra_time_log_output_path=None, sub_queries=None, sub_query_patterns=None,
                    warmup_iterations=0, iterations=1, plan_types=None, input_format='parquet',
                    keep_sc=True, allow_failure=True)

    def test_active_analysis_rejects_existing_tables_before_any_new_table_is_created(self):
        for driver in (nds_power, nds_h_power):
            for mode in ('table', 'all_columns'):
                with self.subTest(driver=driver.__name__, mode=mode):
                    self.tearDown()
                    driver._create_data_source_table(self.spark, 'facts', str(self.root / 'old'), 'parquet')
                    with patch.object(driver, 'get_schemas',
                                      return_value={'fresh': self.schema, 'facts': self.schema}):
                        with self.assertRaisesRegex(ValueError, 'fresh catalog tables'):
                            if driver is nds_power:
                                driver.setup_tables(self.spark, str(self.root / 'inputs'), 'parquet',
                                                    False, [], analyze=mode)
                            else:
                                driver.setup_tables(self.spark, str(self.root / 'inputs'), 'parquet',
                                                    [], analyze=mode)
                    self.assertFalse(self.spark.catalog.tableExists('fresh'))
                    self.assertEqual([row.payload for row in self.spark.table('facts').collect()], [111])

    def test_extra_timing_csv_uses_integer_milliseconds_and_json_retains_fraction(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            options = self.options(output)
            options.update(analyze='all_columns', json_summary_folder=str(output / 'reports'),
                           extra_time_log_output_path=str(output / 'extra'))
            with patch.object(nds_power, 'get_schemas', return_value={'facts': self.schema}), \
                    patch.object(benchmark_statistics.time, 'perf_counter_ns',
                                 side_effect=[0, 1000000, 2000000, 25750000]), \
                    patch.object(nds_power, 'clearQueryName'), \
                    contextlib.redirect_stdout(io.StringIO()):
                nds_power.run_query_stream(**options)
            with (output / 'times.csv').open() as stream:
                rows = list(csv.DictReader(stream))
            timings = {row['query']: row['time/milliseconds'] for row in rows}
            self.assertEqual(timings['Statistics Time'], '25')
            for row in rows:
                int(row['time/milliseconds'])
            exported = []
            for part in (output / 'extra').glob('part-*.csv'):
                with part.open() as stream:
                    exported.extend(csv.reader(stream))
            self.assertEqual(sorted(exported),
                             sorted([row['application_id'], row['query'], row['time/milliseconds']]
                                    for row in rows))
            report = json.loads((output / 'reports/statistics/analyze-cost.json').read_text())
            self.assertEqual(report['duration_ms'], 25.75)

    def test_disabled_and_legacy_nds_runs_remove_only_the_reserved_statistics_file(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            report_folder = output / 'reports'
            statistics_folder = report_folder / 'statistics'
            statistics_folder.mkdir(parents=True)
            unrelated = statistics_folder / 'notes.txt'
            unrelated.write_text('keep me')
            for mode, legacy in ((None, False), ('none', False), (None, True)):
                with self.subTest(mode=mode, legacy=legacy):
                    self.tearDown()
                    cost = statistics_folder / 'analyze-cost.json'
                    cost.write_text('{"mode": "all_columns", "duration_ms": 50.5}')
                    with patch.object(nds_power, 'get_schemas', return_value={'facts': self.schema}), \
                            patch.object(nds_power, 'clearQueryName'), \
                            contextlib.redirect_stdout(io.StringIO()), \
                            contextlib.redirect_stderr(io.StringIO()):
                        nds_power.run_query_stream(**self.options(output), analyze=mode,
                                                   analyze_tables=legacy,
                                                   json_summary_folder=str(report_folder))
                    self.assertFalse(cost.exists())
                    self.assertEqual(unrelated.read_text(), 'keep me')
