# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Exercise driver timing around real query submission and result collection."""

import contextlib
import csv
from decimal import Decimal
import io
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'nds'))
import nds_power
import power_timing


class Clock:
    def __init__(self):
        self.elapsed_ns = 0
        self.epoch_ns = 1700000000125000000

    def advance(self, seconds):
        self.elapsed_ns += int(Decimal(str(seconds)) * 1000000000)

    def time_ns(self):
        return self.epoch_ns + self.elapsed_ns

    def time(self):
        return self.time_ns() / 1000000000

    def perf_counter_ns(self):
        return self.elapsed_ns


class PowerTimingTest(unittest.TestCase):
    def run_driver(self, *, query_count=1, submit_seconds=0.1, collect_seconds=0.15,
                   reporter_seconds=0, summary_seconds=0, between_seconds=0,
                   stop_seconds=7, status='Completed', **options):
        clock = Clock()
        events = []

        def collect():
            events.append('collect')
            clock.advance(collect_seconds)
            return [(1,)]

        class Frame:
            columns = ['value']
            _jdf = SimpleNamespace(queryExecution=lambda: None)

            def __init__(self):
                self.write = self

            def collect(self):
                return collect()

            def toDF(self, *args):
                return self

            def format(self, *args):
                return self

            def mode(self, *args):
                return self

            def save(self, *args):
                events.append('write')
                clock.advance(collect_seconds)

        def sql(query):
            events.append(query)
            clock.advance(submit_seconds)
            return Frame()

        def stop():
            events.append('stop')
            clock.advance(stop_seconds)

        session = SimpleNamespace(sql=sql, stop=stop,
                                  conf=SimpleNamespace(get=lambda *args: 'application-timing'),
                                  _jvm=SimpleNamespace(PythonSQLUtils=SimpleNamespace(
                                      explainString=lambda *args: '')))
        builder = Mock()
        builder.appName.return_value.getOrCreate.return_value = session
        builder.remote.return_value = builder

        class Reporter:
            def __init__(self, spark, name):
                self.summary = {'query': name, 'queryTimes': [], 'queryStatus': []}

            def report_on(self, fn, warmups, iterations, *args):
                for _ in range(warmups):
                    fn(*args)
                for _ in range(iterations):
                    start = clock.elapsed_ns
                    fn(*args)
                    self.summary['queryTimes'].append((clock.elapsed_ns - start) / 1000000)
                    self.summary['queryStatus'].append(status)
                clock.advance(reporter_seconds)
                return self.summary

            def write_summary(self, prefix):
                events.append('summary')
                clock.advance(summary_seconds)

            def is_success(self):
                return all(status == 'Completed' for status in self.summary['queryStatus'])

        query_dict = {f'query{index}': f'SELECT {index}'
                      for index in range(1, query_count + 1)}

        def set_name(spark, name):
            # The first setup precedes submission; later setups are inter-query work.
            events.append('set-name')
            clock.advance(between_seconds)

        def analyze(*args):
            events.append('analyze')
            clock.advance(20)
            return {'duration_ms': 20000}

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'times.csv'
            kwargs = dict(input_prefix='/data', property_file=None, query_dict=query_dict,
                          time_log_output_path=str(path), extra_time_log_output_path=None,
                          sub_queries=None, sub_query_patterns=None, warmup_iterations=0,
                          iterations=1, plan_types=None, keep_sc=True,
                          json_summary_folder=directory if summary_seconds else None)
            kwargs.update(options)
            with contextlib.ExitStack() as stack:
                for name in ('time', 'time_ns', 'perf_counter_ns'):
                    stack.enter_context(patch.object(nds_power.time, name, getattr(clock, name)))
                stack.enter_context(patch.object(nds_power.SparkSession, 'builder', builder))
                stack.enter_context(patch.object(nds_power, '_dataset_tables', return_value={}))
                stack.enter_context(patch.object(nds_power, '_manifest_tables', return_value={}))
                stack.enter_context(patch.object(nds_power, 'setup_tables', side_effect=lambda *args: args[4]))
                stack.enter_context(patch.object(nds_power, 'check_json_summary_folder'))
                stack.enter_context(patch.object(nds_power, 'clear_statistics_summary'))
                stack.enter_context(patch.object(nds_power, 'analyze_catalog', side_effect=analyze))
                stack.enter_context(patch.object(nds_power, 'Profiler', return_value=lambda **kw: contextlib.nullcontext()))
                stack.enter_context(patch.object(nds_power, 'PysparkBenchReport', Reporter))
                stack.enter_context(patch.object(nds_power, 'setQueryName', side_effect=set_name))
                stack.enter_context(patch.object(nds_power, 'clearQueryName'))
                stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
                stack.enter_context(contextlib.redirect_stderr(io.StringIO()))
                nds_power.run_query_stream(**kwargs)
            with path.open() as stream:
                values = {row['query']: Decimal(row['time/milliseconds'])
                          for row in csv.DictReader(stream)}
        return values, events, clock

    @staticmethod
    def full_stream():
        # Exercise the actual parser: it rewrites generated headers and splits
        # the four multi-statement templates into separate runner calls.
        queries = []
        for ordinal, template in enumerate(power_timing.STREAM_ZERO_ORDER, 1):
            statements = ['SELECT 1', 'SELECT 2'] if template in (14, 23, 24, 39) else ['SELECT 1']
            queries.append(f'-- start query {ordinal} in stream 0 using template query{template}.tpl\n'
                           + ';\n'.join(statements) + ';\n'
                           + f'-- end query {ordinal} in stream 0 using template query{template}.tpl\n')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'query_0.sql'
            path.write_text('\n'.join(queries))
            return nds_power.gen_sql_from_stream(str(path))

    def test_complete_default_stream_is_eligible(self):
        values, events, _ = self.run_driver(query_dict=self.full_stream())
        self.assertEqual(values['NDS Metric Eligible'], 1)
        self.assertEqual(values['Query Stream'], 0)
        self.assertEqual(events.count('collect'), 103)
        self.assertEqual(values['Power Test Time'], 25750)

    def test_extended_options_cannot_label_full_stream_eligible(self):
        with tempfile.TemporaryDirectory() as directory:
            modes = [dict(warmup_iterations=1), dict(iterations=2),
                     dict(sub_queries=['query1']), dict(sub_query_patterns=['query1$']),
                     dict(skip_execution=True), dict(output_path='/results'),
                     dict(profiling_hook='/fake-profiler'),
                     dict(save_plan_path=directory, plan_types=[]),
                     dict(analyze='table'), dict(analyze='all_columns'),
                     dict(analyze_tables=True), dict(dataset_manifest='/manifest.json'),
                     dict(cutoff_date='2001-01-01'), dict(spark_connect='sc://server')]
            for mode in modes:
                with self.subTest(mode=mode):
                    values, _, _ = self.run_driver(query_dict=self.full_stream(), **mode)
                    self.assertEqual(values['NDS Metric Eligible'], 0)

    def test_allow_failure_does_not_make_failed_full_stream_eligible(self):
        for status in ('Failed', 'CompletedWithTaskFailures'):
            with self.subTest(status=status):
                values, _, _ = self.run_driver(query_dict=self.full_stream(),
                                                status=status, allow_failure=True)
                self.assertEqual(values['NDS Metric Eligible'], 0)

    def test_subsecond_duration_and_fractional_epoch_endpoints(self):
        values, events, _ = self.run_driver()
        self.assertEqual(values['Power Test Time'], Decimal('250'))
        self.assertEqual(values['Power Start Time'], Decimal('1700000000.125'))
        self.assertEqual(values['Power End Time'], Decimal('1700000000.375'))
        self.assertEqual(events, ['set-name', 'SELECT 1', 'collect'])
        self.assertEqual(values['NDS Timing Version'], 1)
        self.assertEqual(values['NDS Metric Eligible'], 0)  # A one-query diagnostic stream.
        self.assertEqual(values['Query Stream'], -1)

    def test_collect_and_submission_both_belong_to_interval(self):
        values, _, _ = self.run_driver(submit_seconds=2, collect_seconds=3)
        self.assertEqual(values['Power Test Time'], 5000)
        self.assertEqual(values['Power End Time'] - values['Power Start Time'], 5)

    def test_interquery_driver_and_reporting_gaps_are_preserved(self):
        values, events, _ = self.run_driver(query_count=2, between_seconds=2,
                                            reporter_seconds=0.5, summary_seconds=3)
        # Two .25s queries plus the intermediate .5s reporter, 3s summary and 2s setup.
        self.assertEqual(values['Power Test Time'], 6000)
        self.assertEqual(values['Power End Time'] - values['Power Start Time'], 6)
        self.assertEqual(events.count('summary'), 2)
        self.assertEqual(events.count('collect'), 2)

    def test_final_report_and_shutdown_do_not_change_query_interval(self):
        for keep_sc in (True, False):
            with self.subTest(keep_sc=keep_sc):
                values, events, clock = self.run_driver(
                    reporter_seconds=0.5, summary_seconds=9, keep_sc=keep_sc)
                self.assertEqual(values['Power Test Time'], 250)
                self.assertEqual(values['Power End Time'], Decimal('1700000000.375'))
                self.assertEqual(events.count('stop'), 0 if keep_sc else 1)
                self.assertEqual(clock.elapsed_ns, 9750000000 if keep_sc else 16750000000)

    def test_explicit_statistics_remain_outside_power_and_report_is_ineligible(self):
        values, events, _ = self.run_driver(analyze='table')
        self.assertEqual(events[0], 'analyze')
        self.assertEqual(values['Power Test Time'], 250)
        self.assertEqual(values['Power Start Time'], Decimal('1700000020.125'))
        self.assertEqual(values['NDS Metric Eligible'], 0)
        self.assertGreaterEqual(values['Total Time'], 20250)

    def test_legacy_setup_cleanup_timings_remain_separate(self):
        queries = {'query1_setup': 'CREATE TABLE example',
                   'query1': 'SELECT 1', 'query1_cleanup': 'DROP TABLE example'}
        values, events, _ = self.run_driver(query_dict=queries)
        self.assertEqual(events.count('collect'), 3)
        self.assertEqual(values['Power Setup Time'], 250)
        self.assertEqual(values['Power Cleanup Time'], 250)
        self.assertEqual(values['Power Test Time'], 250)
        self.assertEqual(values['NDS Metric Eligible'], 0)

    def test_final_cleanup_profiler_tail_cannot_make_duration_negative(self):
        clocks = []

        class CapturingClock(Clock):
            def __init__(self):
                super().__init__()
                clocks.append(self)

        class SlowProfilerExit:
            def __enter__(self):
                return self

            def __exit__(self, *args):
                clocks[-1].advance(10)

        # Reporter queryTimes includes profiler exit, while the event timer
        # correctly ends at result receipt. Deductions must use the same events.
        with patch.object(sys.modules[__name__], 'Clock', CapturingClock), \
                patch.object(contextlib, 'nullcontext', SlowProfilerExit):
            values, _, _ = self.run_driver(query_dict={'query1_cleanup': 'DROP TABLE example'})
        self.assertEqual(values['Power Cleanup Time'], 250)
        self.assertEqual(values['Power Test Time'], 0)

    def test_empty_stream_produces_zero_duration_and_ineligible_report(self):
        values, events, _ = self.run_driver(query_count=0)
        self.assertEqual(values['Power Test Time'], 0)
        self.assertEqual(values['NDS Metric Eligible'], 0)
        self.assertEqual(events, [])


if __name__ == '__main__':
    unittest.main()
