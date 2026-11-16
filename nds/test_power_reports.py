# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Report-to-score and generated-stream regressions; no Spark runtime required."""

import contextlib
import csv
from decimal import Decimal
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import nds_bench
import power_timing


# TPC-DS 3.2.0 Appendix D, Stream 0. Independent of the production validator.
STREAM_ZERO_ORDER = (
    96, 7, 75, 44, 39, 80, 32, 19, 25, 78, 86, 1, 91, 21, 43, 27, 94, 45,
    58, 64, 36, 33, 46, 62, 16, 10, 63, 69, 60, 59, 37, 98, 85, 70, 67, 28,
    81, 97, 66, 90, 17, 47, 95, 92, 3, 51, 35, 49, 9, 31, 11, 93, 29, 38,
    22, 89, 15, 6, 52, 50, 42, 41, 8, 12, 20, 88, 82, 23, 14, 57, 65, 71,
    34, 48, 30, 74, 87, 77, 73, 84, 54, 55, 56, 2, 26, 40, 72, 53, 79, 18,
    13, 24, 4, 99, 68, 83, 61, 5, 76,
)


def generated_stream(stream=0, order=STREAM_ZERO_ORDER):
    queries = {}
    for ordinal, template in enumerate(order, 1):
        names = ([f'query{template}_part1', f'query{template}_part2']
                 if template in (14, 23, 24, 39) else [f'query{template}'])
        for name in names:
            queries[name] = (f'-- start query {ordinal} in stream {stream} '
                             f'using template query{template}.tpl\nSELECT 1;')
    return queries


def report_fields(stream=0, start='1700000000.125', end='1700000000.375'):
    return {
        'NDS Timing Version': 1,
        'NDS Metric Eligible': 1,
        'Query Stream': stream,
        'Power Start Time': start,
        'Power End Time': end,
        'Power Test Time': (Decimal(end) - Decimal(start)) * 1000,
    }


def write_report(path, fields):
    with Path(path).open('w', newline='') as report:
        writer = csv.writer(report)
        writer.writerow(['application_id', 'query', 'time/milliseconds'])
        writer.writerows(('app', name, value) for name, value in fields.items())


class PowerReportTest(unittest.TestCase):
    def test_elapsed_rounding_retains_exact_decimal_boundaries(self):
        for value, expected in [('0', 0.0), ('0.1', 0.1), ('0.2', 0.2),
                                ('0.3', 0.3), ('0.25', 0.3),
                                ('0.300000001', 0.4), ('3.02', 3.1)]:
            with self.subTest(value=value):
                self.assertEqual(power_timing.round_seconds(Decimal(value)), expected)
        for value in ('-0.1', 'NaN', 'Infinity', '-Infinity'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                power_timing.round_seconds(value)

    def test_query_timer_rejects_wall_clock_jump_but_keeps_monotonic_duration(self):
        epoch = 1_700_000_000_125_000_000
        for wall_span, expected in ((250_000_000, True), (100_000_000_000, False)):
            with self.subTest(wall_span=wall_span), \
                    patch.object(power_timing.time, 'time_ns',
                                 side_effect=[epoch, epoch + wall_span]), \
                    patch.object(power_timing.time, 'perf_counter_ns',
                                 side_effect=[10_000_000_000, 10_250_000_000]):
                timer = power_timing.QueryTimer()
                timer.start()
                timer.finish()
                self.assertEqual(timer.elapsed_ms, 250)
                self.assertEqual(timer.clock_consistent, expected)

    def test_query_timer_without_complete_endpoints_is_not_clock_consistent(self):
        timer = power_timing.QueryTimer()
        self.assertFalse(timer.clock_consistent)
        with patch.object(power_timing.time, 'time_ns', return_value=1_700_000_000_000_000_000), \
                patch.object(power_timing.time, 'perf_counter_ns', return_value=10_000_000_000):
            timer.start()
        self.assertFalse(timer.clock_consistent)

    def test_report_rejects_clock_jump_and_tolerates_submillisecond_serialization(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'power.csv'
            for end, expected in [('1700000100.125', False),
                                  ('1700000000.3750004', True),
                                  ('1700000000.3761', False)]:
                with self.subTest(end=end):
                    fields = report_fields(end=end)
                    fields['Power Test Time'] = 250
                    write_report(path, fields)
                    if expected:
                        self.assertEqual(nds_bench.get_power_time(str(path)), Decimal('250'))
                    else:
                        with self.assertRaises(ValueError):
                            nds_bench.get_power_time(str(path))

    def test_power_consumer_keeps_subsecond_milliseconds_until_conversion(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'power.csv'
            write_report(path, report_fields())
            duration = nds_bench.get_power_time(str(path))
            self.assertIsInstance(duration, Decimal)
            self.assertEqual(duration, Decimal('250'))
            self.assertEqual(nds_bench.round_up_to_nearest_10_percent(duration / 1000), 0.3)

    def test_score_contract_rejects_missing_or_invalid_fields(self):
        fields = report_fields()
        cases = [(name, None) for name in fields]
        cases += [('NDS Timing Version', 0), ('NDS Timing Version', 2),
                  ('NDS Metric Eligible', 0), ('Query Stream', 1),
                  ('Power Start Time', 0), ('Power End Time', -1),
                  ('Power Test Time', 0), ('Power Test Time', -10),
                  ('Power Test Time', 'not-a-number')]
        cases += [(name, value) for name in fields
                  for value in ('NaN', 'Infinity', '-Infinity')]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'power.csv'
            for name, value in cases:
                with self.subTest(name=name, value=value):
                    candidate = dict(fields)
                    if value is None:
                        del candidate[name]
                    else:
                        candidate[name] = value
                    write_report(path, candidate)
                    with self.assertRaises(ValueError):
                        nds_bench.get_power_time(str(path))

    def test_duplicate_contract_field_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'power.csv'
            write_report(path, report_fields())
            with path.open('a') as report:
                report.write('app,NDS Metric Eligible,1\n')
            with self.assertRaisesRegex(ValueError, 'Duplicate'):
                nds_bench.get_power_time(str(path))

    def test_throughput_uses_fractional_enclosing_interval_for_both_halves(self):
        with tempfile.TemporaryDirectory() as directory:
            base = str(Path(directory) / 'throughput')
            for stream in range(1, 9):
                # Four .25s runs with .1s launch gaps span .55s, rounded to .6s.
                start = Decimal('1700000000.125') + Decimal(stream - 1) / 10
                write_report(f'{base}_{stream}.csv',
                             report_fields(stream, str(start), str(start + Decimal('.25'))))
            self.assertEqual(nds_bench.get_throughput_time(base, 9, 1), 0.6)
            self.assertEqual(nds_bench.get_throughput_time(base, 9, 2), 0.6)
            write_report(f'{base}_5.csv', report_fields(0))
            with self.assertRaises(ValueError):
                nds_bench.get_throughput_time(base, 9, 2)


class GeneratedStreamTest(unittest.TestCase):
    def test_complete_split_stream_has_declared_identity(self):
        for stream in (0, 1, 20, 21):
            with self.subTest(stream=stream):
                queries = generated_stream(stream)
                self.assertEqual(len(queries), 103)
                self.assertEqual(power_timing.stream_number(queries), stream)

    def test_incomplete_mixed_or_extended_stream_is_ineligible(self):
        complete = generated_stream()
        missing_template = dict(complete)
        missing_template.pop('query76')
        missing_part = dict(complete)
        missing_part.pop('query14_part2')
        mixed_stream = dict(complete)
        mixed_stream['query76'] = mixed_stream['query76'].replace('in stream 0', 'in stream 1')
        bad_ordinal = dict(complete)
        bad_ordinal['query76'] = bad_ordinal['query76'].replace('query 99 in', 'query 98 in')
        setup = dict(complete)
        setup['query1_setup'] = '-- start query 100 in stream 0 using template query1.tpl\nSELECT 1;'
        for queries in ({}, missing_template, missing_part, mixed_stream, bad_ordinal,
                        setup, {'my_query': 'SELECT 1'}):
            with self.subTest(keys=len(queries)):
                self.assertEqual(power_timing.stream_number(queries), -1)

    def test_power_stream_requires_appendix_d_order(self):
        self.assertEqual(power_timing.stream_number(
            generated_stream(0, tuple(reversed(STREAM_ZERO_ORDER)))), -1)


class ReusedReportsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.config = nds_bench.get_yaml_params(Path(__file__).with_name('bench.yml'))
        for phase in ('data_gen', 'load_test', 'generate_query_stream',
                      'power_test', 'throughput_test', 'maintenance_test'):
            self.config[phase]['skip'] = True
        self.config['power_test']['output_path'] = None
        self.config['load_test']['report_path'] = str(self.root / 'load.txt')
        (self.root / 'load.txt').write_text('Load Test Time: 10.01 seconds\n')
        self.power = self.root / 'power.csv'
        self.config['power_test']['report_path'] = str(self.power)
        write_report(self.power, report_fields())
        self.throughput = str(self.root / 'throughput')
        self.config['throughput_test']['report_base_path'] = self.throughput
        for stream in range(1, 9):
            start = Decimal('1700000000.125') + Decimal(stream - 1) / 10
            write_report(f'{self.throughput}_{stream}.csv',
                         report_fields(stream, str(start), str(start + Decimal('.25'))))
        maintenance = str(self.root / 'maintenance')
        self.config['maintenance_test']['maintenance_report_base_path'] = maintenance
        for refresh in range(1, 5):
            write_report(f'{maintenance}_{refresh}.csv', {'Data Maintenance Time': '.25'})
        self.metrics = self.root / 'metrics.csv'
        self.config['metrics_report_path'] = str(self.metrics)

    def test_skipped_phases_consume_reports_and_round_power_once(self):
        with patch.object(nds_bench.subprocess, 'run') as run, \
                contextlib.redirect_stdout(io.StringIO()):
            nds_bench.run_full_bench(self.config)
        run.assert_not_called()
        with self.metrics.open() as report:
            metrics = dict(csv.reader(report))
        for name, expected in [('TPower', .3), ('Tld', 10.1), ('Ttt1', .6),
                               ('Ttt2', .6), ('Tdm1', .5), ('Tdm2', .5)]:
            self.assertEqual(float(metrics[name]), expected)
        expected = nds_bench.get_perf_metric('10000', 4, 10.1, .3, .6, .6, .5, .5)
        self.assertEqual(int(metrics['perf_metric']), expected)

    def test_reused_ineligible_power_report_never_writes_metrics(self):
        fields = report_fields()
        fields['NDS Metric Eligible'] = 0
        write_report(self.power, fields)
        with patch.object(nds_bench.subprocess, 'run') as run:
            with self.assertRaises(ValueError):
                nds_bench.run_full_bench(self.config)
        run.assert_not_called()
        self.assertFalse(self.metrics.exists())

    def test_reused_legacy_throughput_report_never_writes_metrics(self):
        fields = report_fields(5)
        del fields['NDS Timing Version']
        write_report(f'{self.throughput}_5.csv', fields)
        with patch.object(nds_bench.subprocess, 'run') as run:
            with self.assertRaises(ValueError):
                nds_bench.run_full_bench(self.config)
        run.assert_not_called()
        self.assertFalse(self.metrics.exists())

    def test_invalid_reused_report_fails_before_enabled_data_or_load_work(self):
        self.config['data_gen']['skip'] = False
        self.config['load_test']['skip'] = False
        for path, stream in ((self.power, 0), (f'{self.throughput}_5.csv', 5)):
            with self.subTest(report=path):
                fields = report_fields(stream)
                fields['NDS Metric Eligible'] = 0
                write_report(path, fields)
                with patch.object(nds_bench.subprocess, 'run') as run:
                    with self.assertRaises(ValueError):
                        nds_bench.run_full_bench(self.config)
                run.assert_not_called()
                self.assertFalse(self.metrics.exists())
                write_report(path, report_fields(stream))

    def test_result_file_mode_fails_before_any_subprocess(self):
        self.config['data_gen']['skip'] = False
        self.config['power_test']['output_path'] = '/query-results'
        with patch.object(nds_bench.subprocess, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'result collection'):
                nds_bench.run_full_bench(self.config)
        run.assert_not_called()
        self.assertFalse(self.metrics.exists())


if __name__ == '__main__':
    unittest.main()
