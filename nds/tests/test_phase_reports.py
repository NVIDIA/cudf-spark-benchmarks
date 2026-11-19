# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import contextlib
import csv
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_maintenance
import nds_power


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
                        contextlib.redirect_stdout(io.StringIO()):
                    nds_power.run_query_stream('/tables', None, queries, str(path), None,
                                               None, None, 0, 1, [], input_format='iceberg')
                with path.open() as stream:
                    timings = {r['query']: r['time/milliseconds'] for r in csv.DictReader(stream)}
                self.assertEqual(timings['Power Run Is Metric Compatible'], compatible)

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
