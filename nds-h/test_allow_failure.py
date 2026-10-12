# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES.
# All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check failure exits and CLI plumbing without starting Spark."""

import argparse
import ast
import contextlib
import csv
import io
import os
from pathlib import Path
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


SOURCE = Path(__file__).with_name('nds_h_power.py')


def source_nodes():
    return ast.parse(SOURCE.read_text()).body


def run_function(namespace):
    node = next(node for node in source_nodes()
                if isinstance(node, ast.FunctionDef) and node.name == 'run_query_stream')
    exec(compile(ast.Module(body=[node], type_ignores=[]), str(SOURCE), 'exec'), namespace)
    return namespace['run_query_stream']


class AllowFailureTest(unittest.TestCase):
    def test_query_and_task_failure_exits_are_opt_in(self):
        for status in ('Failed', 'CompletedWithTaskFailures', 'Completed'):
            for allow in (False, True):
                with self.subTest(status=status, allow=allow), tempfile.TemporaryDirectory() as directory:
                    session = SimpleNamespace(stop=Mock())
                    builder = Mock()
                    builder.appName.return_value.getOrCreate.return_value = session
                    report = Mock()
                    report.summary = {'query': 'query1', 'queryStatus': [status],
                                      'queryTimes': [25]}
                    report.report_on.return_value = report.summary
                    report.is_success.return_value = status == 'Completed'
                    namespace = {
                        'csv': csv, 'os': os, 'sys': sys, 'time': time,
                        'SparkSession': SimpleNamespace(builder=builder),
                        '_get_app_id': lambda session: 'application-test',
                        'setup_tables': lambda session, prefix, fmt, times, analyze: times,
                        'check_json_summary_folder': lambda path: None,
                        'Profiler': lambda **kwargs: lambda **kwargs2: contextlib.nullcontext(),
                        'setQueryName': Mock(), 'clearQueryName': Mock(),
                        'PysparkBenchReport': lambda session, name: report,
                        'run_one_query': Mock(),
                    }
                    run = run_function(namespace)
                    log = Path(directory) / 'times.csv'
                    with contextlib.redirect_stdout(io.StringIO()):
                        arguments = ('/facts', None, {'query1': 'select 1'}, str(log),
                                     None, 0, 1, ['logical'], 'parquet')
                        if allow:
                            self.assertIsNone(run(*arguments, json_summary_folder=directory,
                                                  allow_failure=True))
                        else:
                            with self.assertRaises(SystemExit) as stopped:
                                run(*arguments, json_summary_folder=directory)
                            self.assertEqual(stopped.exception.code, int(status != 'Completed'))
                    session.stop.assert_called_once()
                    report.write_summary.assert_called_once_with(prefix=directory + os.sep)
                    self.assertEqual(report.summary['queryStatus'], [status])
                    with log.open() as stream:
                        rows = list(csv.reader(stream))
                    self.assertEqual(rows[0], ['application_id', 'query', 'time/milliseconds'])
                    self.assertEqual(rows[1], ['application-test', 'query1', '25'])
                    self.assertIn('Power Test Time', [row[1] for row in rows])

    def test_cli_passes_false_by_default_and_true_with_flag(self):
        main = next(node for node in source_nodes() if isinstance(node, ast.If) and
                    isinstance(node.test, ast.Compare) and
                    isinstance(node.test.left, ast.Name) and node.test.left.id == '__name__')
        for flags, expected in (([], False), (['--allow_failure'], True)):
            with self.subTest(flags=flags):
                run = Mock()
                namespace = {'__name__': '__main__', 'argparse': argparse,
                             'gen_sql_from_stream': lambda path: {'query1': 'select 1'},
                             'run_query_stream': run}
                argv = ['nds_h_power.py', '/facts', 'queries.sql', 'times.csv', *flags]
                with patch.object(sys, 'argv', argv):
                    exec(compile(ast.Module(body=[main], type_ignores=[]),
                                 str(SOURCE), 'exec'), namespace)
                self.assertIs(run.call_args.args[-1], expected)


if __name__ == '__main__':
    unittest.main()
