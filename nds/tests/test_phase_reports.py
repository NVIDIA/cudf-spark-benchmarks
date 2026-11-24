# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import contextlib
import csv
from datetime import datetime, timedelta, timezone
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_bench
import nds_maintenance
import nds_power
from phase_report import read_phase_metrics


class PhaseReportTest(unittest.TestCase):
    def test_query_executes_with_python36_wall_clock(self):
        clock = Mock(spec=['time'])
        clock.time.side_effect = [10.25, 10.75]
        session = Mock()
        timing = {}
        with patch.object(nds_power, 'time', clock):
            nds_power.run_one_query(session, nds_power.Profiler(None, None), 'SELECT 1',
                                    'query1', None, None, None, None, False, timing)
        session.sql.assert_called_once_with('SELECT 1')
        session.sql.return_value.collect.assert_called_once_with()
        self.assertEqual(timing, {'start_ns': 10_250_000_000, 'end_ns': 10_750_000_000,
                                  'query_ns': 500_000_000})

    def test_power_report_spans_first_submission_to_final_result(self):
        now_ns = 100_125_000_000

        def advance(milliseconds):
            nonlocal now_ns
            now_ns += int(milliseconds * 1_000_000)

        clock = Mock()
        clock.time_ns.side_effect = lambda: now_ns
        clock.time.side_effect = lambda: now_ns / 1_000_000_000
        session = Mock()
        session.version = '3.5.5'
        session.sparkContext._conf.getAll.return_value = []

        def submit(query):
            advance(100)
            frame = Mock()
            frame.collect.side_effect = lambda: advance(125.25)
            return frame

        session.sql.side_effect = submit
        builder = Mock()
        builder.appName.return_value.getOrCreate.return_value = session
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'power.csv'
            with patch.object(nds_power.SparkSession, 'builder', builder), \
                    patch.object(nds_power.PysparkBenchReport, '_register_python_listener',
                                 return_value=None), \
                    patch.object(nds_power, 'time', clock), \
                    patch.object(nds_power, 'setQueryName', side_effect=lambda *_: advance(500)), \
                    patch.object(nds_power, 'clearQueryName', side_effect=lambda *_: advance(2000)):
                nds_power.run_query_stream('/tables', None,
                                           {'query1': 'SELECT 1', 'query2': 'SELECT 2'},
                                           str(path), None, None, None, 0, 1, [],
                                           input_format='iceberg')
            with path.open() as stream:
                reader = csv.DictReader(stream)
                self.assertEqual(reader.fieldnames, ['application_id', 'query', 'time/milliseconds'])
                rows = [(r['query'], r['time/milliseconds']) for r in reader]
            self.assertEqual([key for key, _ in rows],
                             ['query1', 'query2', 'Power Start Time', 'Power End Time',
                              'Power Test Time', 'Total Time'])
            self.assertEqual([value for _, value in rows[2:5]], ['100', '101', '950'])
            metrics = read_phase_metrics(path)
            self.assertEqual(float(metrics['Power Start Time']), 100.625)
            self.assertEqual(float(metrics['Power End Time']), 101.5755)
            self.assertEqual(float(metrics['Power Test Time']), 950.5)
            with self.assertRaisesRegex(ValueError, 'complete query stream'):
                nds_bench.get_power_time(path)

    def test_maintenance_report_spans_refresh_read_to_final_result(self):
        start = datetime(2026, 1, 1, tzinfo=timezone.utc)
        now = start

        def advance(seconds):
            nonlocal now
            now += timedelta(seconds=seconds)

        def read_refresh_inputs():
            advance(5)
            return {'DF_CS': ['refresh SQL']}

        session = Mock()
        session.version = '3.5.5'
        session.sparkContext._conf.getAll.return_value = []
        session.sql.return_value.collect.side_effect = lambda: advance(0.25)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'maintenance.csv'
            with patch.object(nds_maintenance, 'datetime') as clock, \
                    patch.object(nds_maintenance.PysparkBenchReport, '_register_python_listener',
                                 return_value=None), \
                    patch.object(nds_maintenance, 'clearQueryName', side_effect=lambda *_: advance(2)):
                clock.now.side_effect = lambda: now
                nds_maintenance.run_query(session, read_refresh_inputs, str(path), None,
                                          None, '/tables', 'iceberg', True)
            with path.open() as stream:
                reader = csv.DictReader(stream)
                self.assertEqual(reader.fieldnames, ['application_id', 'query', 'time/s'])
                rows = [(r['query'], r['time/s']) for r in reader]
            self.assertEqual([key for key, _ in rows],
                             ['DF_CS', 'Data Maintenance Start Time', 'Data Maintenance End Time',
                              'Data Maintenance Time', 'Total Time'])
            self.assertEqual(rows[1:4], [('Data Maintenance Start Time', str(start)),
                                         ('Data Maintenance End Time', str(start + timedelta(seconds=5.25))),
                                         ('Data Maintenance Time', '5.25')])
            metrics = read_phase_metrics(path)
            self.assertEqual(float(metrics['Data Maintenance Start Timestamp']), start.timestamp())
            self.assertEqual(float(metrics['Data Maintenance End Timestamp']), start.timestamp() + 5.25)
            with self.assertRaisesRegex(ValueError, 'rerun maintenance'):
                nds_bench.get_maintenance_start_end_time(path)

    def test_full_power_stream_checks_session_returned_by_builder(self):
        class ConnectSession(Mock):
            __module__ = 'pyspark.sql.connect.session'

        queries = {}
        for number in range(1, 100):
            suffixes = ('_part1', '_part2') if number in (14, 23, 24, 39) else ('',)
            for suffix in suffixes:
                queries[f'query{number}{suffix}'] = 'SELECT 1'
        for session, compatible in [(Mock(), '1'), (ConnectSession(), '0')]:
            with self.subTest(compatible=compatible), tempfile.TemporaryDirectory() as directory:
                builder = Mock()
                builder.appName.return_value.getOrCreate.return_value = session
                report = Mock()
                report.summary = {'queryTimes': [1], 'queryStatus': ['Completed']}
                report.report_on.return_value = report.summary
                path = Path(directory) / 'times.csv'
                with patch.object(nds_power.SparkSession, 'builder', builder), \
                        patch.object(nds_power, 'PysparkBenchReport', return_value=report), \
                        patch.object(nds_power.time, 'time', side_effect=[99, 100.125, 101.625, 102]), \
                        contextlib.redirect_stdout(io.StringIO()):
                    nds_power.run_query_stream('/tables', None, queries, str(path), None,
                                               None, None, 0, 1, [], input_format='iceberg')
                self.assertEqual(read_phase_metrics(path)['Power Run Is Metric Compatible'], compatible)
                if compatible == '1':
                    self.assertEqual(float(nds_bench.get_power_time(path)), 1500)
                    path.write_text(path.read_text() + 'different-app,query1,12\n')
                    with self.assertRaisesRegex(ValueError, 'do not match'):
                        nds_bench.get_power_time(path)
                    Path(f'{path}.metrics.json').unlink()
                    with self.assertRaisesRegex(ValueError, 'legacy reports'):
                        nds_bench.get_power_time(path)

    def test_failed_maintenance_saves_diagnostics_before_stopping(self):
        for status in ['Failed', 'CompletedWithTaskFailures']:
            with self.subTest(status=status), tempfile.TemporaryDirectory() as directory:
                session = Mock()
                session.version = '3.5.5'
                session.sparkContext._conf.getAll.return_value = []
                if status == 'Failed':
                    session.sql.side_effect = ValueError('invalid refresh SQL')
                listener = Mock()
                listener.failures = ['task failed'] if status == 'CompletedWithTaskFailures' else []
                reports = Path(directory) / 'reports'
                timings = Path(directory) / 'times.csv'
                with patch.dict('os.environ', {}, clear=True), \
                        patch.object(nds_maintenance.PysparkBenchReport,
                                     '_register_python_listener', return_value=listener):
                    with self.assertRaisesRegex(RuntimeError, 'query failed: DF_CS'):
                        nds_maintenance.run_query(session, {'DF_CS': ['refresh SQL']}, str(timings),
                                                  str(reports), None, '/tables', 'iceberg', True)
                self.assertFalse(timings.exists())
                summary_file, = reports.glob('*.json')
                summary = json.loads(summary_file.read_text())
                self.assertEqual(summary['queryStatus'], [status])
                if status == 'Failed':
                    self.assertEqual(summary['exceptions'], ['invalid refresh SQL'])
