# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test NDS-H failure reporting without starting a Spark process."""

import contextlib
import csv
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_h_power as driver


class AllowFailureTest(unittest.TestCase):
    def test_query_and_task_failures_preserve_reports_and_control_exit(self):
        for status in ('Failed', 'CompletedWithTaskFailures', 'Completed'):
            for allow in (False, True):
                with self.subTest(status=status, allow=allow), tempfile.TemporaryDirectory() as directory:
                    session = Mock()
                    session.conf.get.return_value = 'application-test'
                    builder = Mock()
                    builder.appName.return_value.getOrCreate.return_value = session
                    report = driver.PysparkBenchReport(session, 'query1')
                    report.summary.update({'queryStatus': [status], 'queryTimes': [25],
                                           'startTime': 123})
                    report.report_on = Mock(return_value=report.summary)
                    log = Path(directory) / 'times.csv'
                    with patch.object(driver.SparkSession, 'builder', builder), \
                            patch.object(driver, 'setup_tables', side_effect=lambda *args: args[3]), \
                            patch.object(driver, 'Profiler', return_value=lambda **args: contextlib.nullcontext()), \
                            patch.object(driver, 'setQueryName'), patch.object(driver, 'clearQueryName'), \
                            patch.object(driver, 'PysparkBenchReport', return_value=report), \
                            contextlib.redirect_stdout(io.StringIO()):
                        arguments = ('/facts', None, {'query1': 'select 1'}, str(log),
                                     None, 0, 1, ['logical'], 'parquet')
                        if allow:
                            self.assertIsNone(driver.run_query_stream(
                                *arguments, json_summary_folder=directory, allow_failure=True))
                        else:
                            with self.assertRaises(SystemExit) as stopped:
                                driver.run_query_stream(*arguments, json_summary_folder=directory)
                            self.assertEqual(stopped.exception.code, int(status != 'Completed'))
                    summaries = list(Path(directory).glob('*.json'))
                    self.assertEqual(len(summaries), 1)
                    with summaries[0].open() as stream:
                        summary = json.load(stream)
                    self.assertEqual(summary['query'], 'query1')
                    self.assertEqual(summary['queryStatus'], [status])
                    self.assertEqual(summary['queryTimes'], [25])
                    with log.open() as stream:
                        rows = list(csv.reader(stream))
                    self.assertEqual(rows[0], ['application_id', 'query', 'time/milliseconds'])
                    self.assertEqual(rows[1], ['application-test', 'query1', '25'])
                    self.assertIn('Power Test Time', [row[1] for row in rows])

    def test_allow_failure_does_not_swallow_setup_errors(self):
        builder = Mock()
        builder.appName.return_value.getOrCreate.return_value.conf.get.return_value = 'application-test'
        error = RuntimeError('Cannot load the benchmark dataset')
        with patch.object(driver.SparkSession, 'builder', builder), \
                patch.object(driver, 'setup_tables', side_effect=error):
            with self.assertRaises(RuntimeError) as stopped:
                driver.run_query_stream('/missing', None, {'query1': 'select 1'}, 'times.csv',
                                        None, 0, 1, ['logical'], 'parquet', allow_failure=True)
            self.assertIs(stopped.exception, error)

    def test_cli_documents_allow_failure(self):
        result = subprocess.run([sys.executable, str(Path(driver.__file__)), '--help'],
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0)
        self.assertIn('--allow_failure', result.stdout)


if __name__ == '__main__':
    unittest.main()
