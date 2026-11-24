# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check Python garbage collection after each query attempt in both PySpark power runners."""

import contextlib
import csv
import io
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, call, patch

from pyspark.sql import SparkSession

ROOT = Path(__file__).resolve().parents[2]
with patch.object(sys, 'path', [str(ROOT / 'nds'), str(ROOT / 'utils'), *sys.path]):
    import PysparkBenchReport as nds_report
    import python_benchmark_reporter.PysparkBenchReport as nds_h_report
    import nds_bench
    import nds_power
    from phase_report import read_phase_metrics

TIMED_COLLECTION = [call.clock_ns(), call.collect(), call.clock_ns()]
# Each runner: its reporter module, its script, and its stream's query header.
NDS = (nds_report, ROOT / 'nds/nds_power.py', '-- start query {0} using template query{0}.tpl')
NDS_H = (nds_h_report, ROOT / 'nds-h/nds_h_power.py', '-- Template file: {0}\n')


class PythonGcAfterQueryTest(unittest.TestCase):
    @contextlib.contextmanager
    def _quiet_reports(self):
        with patch.object(nds_report.PysparkBenchReport, '_register_python_listener',
                          return_value=None), \
                patch.object(nds_h_report, 'PythonListener', return_value=Mock(failures=[])), \
                contextlib.redirect_stdout(io.StringIO()), \
                contextlib.redirect_stderr(io.StringIO()):
            yield

    @contextlib.contextmanager
    def _mocked_report(self, module, events):
        spark = Mock(version='3.5.5')
        spark.sparkContext._conf.getAll.return_value = []
        clock = SimpleNamespace(time=events.clock, time_ns=events.clock_ns)
        with self._quiet_reports(), \
                patch.object(module, 'time', clock), \
                patch.object(module, 'gc', SimpleNamespace(collect=events.collect)):
            yield module.PysparkBenchReport(spark, 'query1')

    def _run_power(self, runner, flags, collection_seconds, queries=2, failed_starts=()):
        """Run a power runner's command line on mocked Spark and a fake clock, in which each query
        takes 1 s and each collection the next of collection_seconds. A query in failed_starts has
        its profiler start fail, as a failing start hook does. Return the mocked calls, the CSV
        rows, the JSON summaries by query, and the companion's metrics, or None without one."""
        module, script, header = runner
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            stream = directory / 'stream.sql'
            stream.write_text(''.join(f'{header.format(i)}\nselect {i};\n'
                                      for i in range(1, queries + 1)))
            time_log = directory / 'times.csv'
            summaries = directory / 'summaries'
            now_ns = 100_000_000_000

            def advance(seconds):
                nonlocal now_ns
                now_ns += seconds * 1_000_000_000

            def start_profiling(profiler):
                if profiler.query_name in failed_starts:
                    raise subprocess.CalledProcessError(1, ['hook', 'start'])

            durations = iter(collection_seconds)
            events = Mock()
            events.collect.side_effect = lambda: advance(next(durations))
            for number in range(1, queries + 1):
                getattr(events, f'query{number}').side_effect = lambda: advance(1)
            spark = Mock(version='3.5.5')
            spark.sparkContext._conf.getAll.return_value = []
            spark.sql.side_effect = lambda sql: SimpleNamespace(
                collect=getattr(events, 'query' + sql.split()[-1].rstrip(';')))
            builder = Mock()
            builder.appName.return_value.getOrCreate.return_value = spark
            argv = [str(script), '/facts', str(stream), str(time_log),
                    '--input_format', 'iceberg', '--allow_failure',
                    '--json_summary_folder', str(summaries), *flags]

            with self._quiet_reports(), \
                    patch.object(module, 'gc', SimpleNamespace(collect=events.collect)), \
                    patch.object(nds_power.Profiler, 'start_profiling', start_profiling), \
                    patch.object(time, 'time', lambda: now_ns / 1_000_000_000), \
                    patch.object(time, 'time_ns', lambda: now_ns), \
                    patch.object(SparkSession, 'builder', builder), \
                    patch.object(sys, 'argv', argv), \
                    patch.object(sys, 'path', [str(script.parent), *sys.path]):
                runpy.run_path(str(script), run_name='__main__')

            with time_log.open(newline='') as output:
                rows = [(row['query'], int(row['time/milliseconds']))
                        for row in csv.DictReader(output)]
            summaries_by_query = {}
            for path in summaries.glob('*.json'):
                summary = json.loads(path.read_text())
                summaries_by_query[summary['query']] = summary
            companion = Path(f'{time_log}.metrics.json')
            metrics = read_phase_metrics(time_log) if companion.exists() else None
        return events, rows, summaries_by_query, metrics

    def test_reporter_collects_after_each_attempt_outside_query_times(self):
        for module in (nds_report, nds_h_report):
            for enabled in (False, True):
                with self.subTest(reporter=module.__name__, enabled=enabled):
                    spans = [(500_000_000, 502_000_000), (1_500_000_000, 1_503_500_000),
                             (2_500_000_000, 2_504_000_000), (3_500_000_000, 3_504_500_000)]
                    events = Mock()
                    events.clock.side_effect = [1, 2, 3, 4, 6]
                    events.clock_ns.side_effect = [ns for span in spans for ns in span]
                    events.query.side_effect = [None, RuntimeError('warmup failed'),
                                                RuntimeError('query failed'), None]
                    events.collect.side_effect = lambda: self.assertIsNone(sys.exc_info()[0])
                    with self._mocked_report(module, events) as report:
                        options = {'python_gc_after_query': True} if enabled else {}
                        summary = report.report_on(events.query, 3, 2, 'argument', **options)

                    collection = TIMED_COLLECTION if enabled else []
                    self.assertEqual(events.mock_calls, [
                        call.query('argument'), *collection,
                        call.query('argument'), *collection,
                        call.clock(),
                        call.clock(), call.query('argument'), call.clock(), *collection,
                        call.clock(), call.query('argument'), call.clock(), *collection,
                    ])
                    self.assertEqual(summary['startTime'], 1000)
                    self.assertEqual(summary['queryTimes'], [1000, 2000])
                    self.assertEqual(summary['queryStatus'], ['Failed', 'Completed'])
                    self.assertEqual(summary['exceptions'], ['query failed'])
                    if enabled:
                        self.assertEqual(summary['pythonGcTimes'], [2.0, 3.5, 4.0, 4.5])
                    else:
                        self.assertNotIn('pythonGcTimes', summary)
                    if module is nds_report:
                        self.assertEqual(report.python_gc_spans, spans if enabled else [])

    def test_interrupted_attempt_is_not_collected(self):
        for module in (nds_report, nds_h_report):
            with self.subTest(reporter=module.__name__):
                events = Mock()
                events.clock_ns.side_effect = [500_000_000, 502_000_000]
                events.query.side_effect = [None, KeyboardInterrupt]
                with self._mocked_report(module, events) as report:
                    with self.assertRaises(KeyboardInterrupt):
                        report.report_on(events.query, 2, 1, python_gc_after_query=True)
                self.assertEqual(events.mock_calls,
                                 [call.query(), *TIMED_COLLECTION, call.query()])
                self.assertEqual(report.summary['pythonGcTimes'], [2.0])

    def test_full_power_stream_with_collection_is_not_scored(self):
        queries = {}
        for number in range(1, 100):
            suffixes = ('_part1', '_part2') if number in (14, 23, 24, 39) else ('',)
            for suffix in suffixes:
                queries[f'query{number}{suffix}'] = 'SELECT 1'
        for enabled, compatible in ((False, '1'), (True, '0')):
            with self.subTest(enabled=enabled), tempfile.TemporaryDirectory() as directory:
                builder = Mock()
                builder.appName.return_value.getOrCreate.return_value = Mock()
                report = Mock()
                report.summary = {'queryTimes': [1], 'queryStatus': ['Completed'],
                                  'pythonGcTimes': [2.0]}
                report.python_gc_spans = [(101_000_000_000, 101_002_000_000)]
                report.report_on.return_value = report.summary
                path = Path(directory) / 'times.csv'
                with patch.object(nds_power.SparkSession, 'builder', builder), \
                        patch.object(nds_power, 'PysparkBenchReport', return_value=report), \
                        patch.object(time, 'time', side_effect=[99, 100.125, 101.625, 102]), \
                        contextlib.redirect_stdout(io.StringIO()):
                    nds_power.run_query_stream('/tables', None, queries, str(path), None,
                                               None, None, 0, 1, [], input_format='iceberg',
                                               python_gc_after_query=enabled)
                self.assertEqual(read_phase_metrics(path)['Power Run Is Metric Compatible'],
                                 compatible)
                if enabled:
                    with self.assertRaisesRegex(ValueError, 'complete query stream'):
                        nds_bench.get_power_time(path)
                else:
                    self.assertEqual(float(nds_bench.get_power_time(path)), 1500)

    def test_power_cli_reports_collection_in_totals_and_summaries(self):
        # Each case: runner, flags, collections, per-query JSON collection times, Power Test
        # Time, Total Time, and the companion's two collection totals.
        cases = (
            (NDS, [], [], None, 2000, 2000, None),
            (NDS, ['--python_gc_after_query', '--warmup_iterations', '1'], [2, 3, 4, 5],
             {'query1': [2000.0, 3000.0], 'query2': [4000.0, 5000.0]}, 13000, 18000,
             ('14000.0', '9000.0')),
            (NDS_H, [], [], None, 2000, 2000, None),
            (NDS_H, ['--python_gc_after_query', '--warmup_iterations', '1'], [2, 3, 4, 5],
             {'query1': [2000.0, 3000.0], 'query2': [4000.0, 5000.0]}, 18000, 18000, None),
        )
        for (runner, flags, collection_seconds, summary_gc_times, power_ms, total_ms,
             companion_gc) in cases:
            with self.subTest(script=runner[1].name, flags=flags):
                events, rows, summaries, metrics = self._run_power(runner, flags,
                                                                   collection_seconds)

                attempts = 2 if collection_seconds else 1
                collection = [call.collect()] if collection_seconds else []
                self.assertEqual(events.mock_calls,
                                 [call.query1(), *collection] * attempts +
                                 [call.query2(), *collection] * attempts)
                self.assertEqual([name for name, _ in rows],
                                 ['query1', 'query2', 'Power Start Time', 'Power End Time',
                                  'Power Test Time', 'Total Time'])
                times = dict(rows)
                self.assertEqual((times['query1'], times['query2']), (1000, 1000))
                self.assertEqual(times['Power Test Time'], power_ms)
                self.assertEqual(times['Total Time'], total_ms)

                self.assertEqual(set(summaries), {'query1', 'query2'})
                for name, summary in summaries.items():
                    # The CSV holds the one timed attempt's time, as the JSON does.
                    self.assertEqual(summary['queryTimes'], [times[name]])
                    if summary_gc_times is None:
                        self.assertNotIn('pythonGcTimes', summary)
                    else:
                        self.assertEqual(summary['pythonGcTimes'], summary_gc_times[name])

                if runner is NDS_H:
                    self.assertIsNone(metrics)
                    continue
                self.assertEqual(int(float(metrics['Power Test Time'])), power_ms)
                if companion_gc is None:
                    self.assertFalse([key for key in metrics if key.startswith('Python GC')])
                    continue
                self.assertEqual((metrics['Python GC Time'],
                                  metrics['Python GC Time In Power Test Time']), companion_gc)
                # The JSON summaries hold the same collections, the final one outside the interval.
                gc_times = summaries['query1']['pythonGcTimes'] + \
                    summaries['query2']['pythonGcTimes']
                self.assertEqual(float(metrics['Python GC Time']), sum(gc_times))
                self.assertEqual(float(metrics['Python GC Time In Power Test Time']),
                                 sum(gc_times[:-1]))
                self.assertEqual(float(metrics['Power Test Time']) -
                                 float(metrics['Python GC Time In Power Test Time']),
                                 4 * 1000)

    def test_power_counts_collections_inside_recorded_interval(self):
        # A failed profiler start raises before SQL submission, so other attempts set the Power
        # interval, or the query loop does when every start fails. Each query takes 1 s and each
        # collection 2 s. Each case: failed starts, Power Test Time, collection time inside it.
        cases = (
            ((), 7000, 4000),
            (('query1',), 4000, 2000),
            (('query2', 'query3'), 1000, 0),
            (('query1', 'query2', 'query3'), 6000, 6000),
        )
        for failed_starts, power_ms, gc_in_power_ms in cases:
            with self.subTest(failed_starts=failed_starts):
                events, rows, _, metrics = self._run_power(
                    NDS, ['--python_gc_after_query'], [2, 2, 2], queries=3,
                    failed_starts=failed_starts)

                expected_calls = []
                for number in (1, 2, 3):
                    if f'query{number}' not in failed_starts:
                        expected_calls.append(getattr(call, f'query{number}')())
                    expected_calls.append(call.collect())
                self.assertEqual(events.mock_calls, expected_calls)
                self.assertEqual(dict(rows)['Power Test Time'], power_ms)
                self.assertEqual(float(metrics['Python GC Time']), 6000)
                self.assertEqual(float(metrics['Python GC Time In Power Test Time']),
                                 gc_in_power_ms)
