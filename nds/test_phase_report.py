# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import csv
from pathlib import Path
import tempfile
import unittest

import nds_bench
from phase_report import read_phase_metrics, write_phase_report


class MissingPhaseCompanionTest(unittest.TestCase):
    def test_missing_companion_names_file_for_every_scoring_reader(self):
        readers = (read_phase_metrics, nds_bench.get_power_time,
                   nds_bench.get_start_end_time, nds_bench.get_maintenance_start_end_time)
        # Neither a released CSV nor an intermediate CSV with inline scoring
        # markers can supply the precise, hash-checked companion metrics.
        for inline_metrics in (False, True):
            for reader in readers:
                with self.subTest(inline_metrics=inline_metrics, reader=reader.__name__), \
                        tempfile.TemporaryDirectory() as directory:
                    path = Path(directory) / 'phase.csv'
                    rows = [('app', 'query1', '100')]
                    if inline_metrics:
                        rows.extend([
                            ('app', 'Power Run Is Metric Compatible', '1'),
                            ('app', 'Power Start Time', '100.125'),
                            ('app', 'Power End Time', '101.625'),
                            ('app', 'Power Test Time', '1500'),
                            ('app', 'Maintenance Run Is Metric Compatible', '1'),
                            ('app', 'Data Maintenance Start Timestamp', '100.125'),
                            ('app', 'Data Maintenance End Timestamp', '101.625'),
                        ])
                    with path.open('w', newline='') as report:
                        writer = csv.writer(report)
                        writer.writerow(['application_id', 'query', 'time/milliseconds'])
                        writer.writerows(rows)

                    with self.assertRaises(ValueError) as raised:
                        reader(path)
                    message = str(raised.exception)
                    self.assertIn(str(Path(f'{path}.metrics.json')), message)
                    self.assertIn('missing metrics companion', message)
                    self.assertIn('restore', message)
                    self.assertIn('rerun this phase', message)

    def test_companion_round_trip_and_mismatched_csv(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'phase.csv'
            metrics = {'Power Run Is Metric Compatible': '1',
                       'Power Start Time': '100.125', 'Power End Time': '101.625',
                       'Power Test Time': '1500'}
            write_phase_report(path, ['application_id', 'query', 'time/milliseconds'],
                               [('app', 'query1', '1500')], metrics)
            self.assertEqual(read_phase_metrics(path), metrics)
            self.assertEqual(nds_bench.get_power_time(path), '1500')
            self.assertEqual(nds_bench.get_start_end_time(path), ('100.125', '101.625'))
            path.write_text(path.read_text() + 'app,query2,1\n')
            with self.assertRaisesRegex(ValueError, 'do not match'):
                read_phase_metrics(path)


if __name__ == '__main__':
    unittest.main()
