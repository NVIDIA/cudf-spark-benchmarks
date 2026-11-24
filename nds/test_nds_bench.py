# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import unittest
from decimal import Decimal
from pathlib import Path
from unittest.mock import call, mock_open, patch

import nds_bench


class NdsBenchRangeTest(unittest.TestCase):

    def test_get_num_streams_in_throughput(self):
        self.assertEqual(4, nds_bench.get_num_streams_in_throughput(9))
        self.assertEqual(6, nds_bench.get_num_streams_in_throughput(13))

    def test_rejects_invalid_num_streams(self):
        invalid_values = [7, 8, 10, 11, "9", True]
        for num_streams in invalid_values:
            with self.subTest(num_streams=num_streams):
                with self.assertRaises(ValueError):
                    nds_bench.get_num_streams_in_throughput(num_streams)

    def test_throughput_stream_ranges(self):
        for num_streams, first_streams, second_streams in [
                (9, [1, 2, 3, 4], [5, 6, 7, 8]),
                (13, [1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12])]:
            with self.subTest(num_streams=num_streams):
                self.assertEqual(
                    first_streams, nds_bench.get_stream_range(num_streams, 1))
                self.assertEqual(
                    second_streams, nds_bench.get_stream_range(num_streams, 2))

    def test_refresh_run_ranges(self):
        for num_streams, first_refreshes, second_refreshes in [
                (9, [1, 2], [3, 4]), (13, [1, 2, 3], [4, 5, 6])]:
            with self.subTest(num_streams=num_streams):
                self.assertEqual(
                    first_refreshes, nds_bench.get_refresh_range(num_streams, 1))
                self.assertEqual(
                    second_refreshes, nds_bench.get_refresh_range(num_streams, 2))

    def test_rejects_invalid_test_number(self):
        for first_or_second in [0, 3]:
            with self.subTest(first_or_second=first_or_second):
                with self.assertRaises(ValueError):
                    nds_bench.get_stream_range(9, first_or_second)
                with self.assertRaises(ValueError):
                    nds_bench.get_refresh_range(9, first_or_second)


class NdsBenchRefreshRunTest(unittest.TestCase):

    @patch("nds_bench.subprocess.run")
    def test_data_gen_creates_one_refresh_set_per_throughput_stream(
            self, mock_run):
        for num_streams, refresh_count in [(9, 4), (13, 6)]:
            with self.subTest(num_streams=num_streams):
                mock_run.reset_mock()
                nds_bench.run_data_gen(
                    "100", "4", "/data/raw", "hdfs", num_streams)

                expected_calls = [
                    call(["python3", "nds_gen_data.py", "hdfs", "100", "4",
                          "/data/raw", "--overwrite_output"], check=True)
                ]
                expected_calls.extend(
                    call(["python3", "nds_gen_data.py", "hdfs", "100", "4",
                          f"/data/raw_{i}", "--overwrite_output", "--update", str(i)],
                         check=True)
                    for i in range(1, refresh_count + 1)
                )
                self.assertEqual(expected_calls, mock_run.call_args_list)

    @patch("nds_bench.subprocess.run")
    def test_data_gen_validates_stream_count_before_starting(self, mock_run):
        with self.assertRaises(ValueError):
            nds_bench.run_data_gen("100", "4", "/data/raw", "hdfs", 11)

        mock_run.assert_not_called()

    @patch("nds_bench.subprocess.run")
    def test_each_maintenance_test_runs_half_the_refresh_sets(self, mock_run):
        common_args = (9, "/warehouse", "/templates/maintenance",
                       "/data/raw", "/queries/maintenance",
                       "/reports/maintenance", "/properties/bench",
                       "delta")

        nds_bench.maintenance_test(
            common_args[0], 1, *common_args[1:])
        nds_bench.maintenance_test(
            common_args[0], 2, *common_args[1:])

        expected_calls = [
            call(["./spark-submit-template", "/templates/maintenance",
                  "nds_maintenance.py", "/warehouse", f"/data/raw_{i}",
                  "/queries/maintenance", f"/reports/maintenance_{i}.csv",
                  "--property_file", "/properties/bench",
                  "--warehouse_type", "delta"], check=True)
            for i in range(1, 5)
        ]
        self.assertEqual(expected_calls, mock_run.call_args_list)

    @patch("nds_bench.get_maintenance_start_end_time")
    def test_maintenance_time_reads_only_its_refresh_reports(
            self, mock_get_interval):
        for test_number, refresh_numbers in [(1, [1, 2]), (2, [3, 4])]:
            with self.subTest(test_number=test_number):
                mock_get_interval.reset_mock()
                mock_get_interval.side_effect = [(Decimal('0'), Decimal('1.01')),
                                                 (Decimal('2.01'), Decimal('4.02'))]

                result = nds_bench.get_maintenance_time(
                    "/reports/maintenance", 9, test_number)

                self.assertEqual(4.1, result)
                self.assertEqual(
                    [call(f"/reports/maintenance_{i}.csv") for i in refresh_numbers],
                    mock_get_interval.call_args_list)

    @patch("nds_bench.get_start_end_time")
    def test_throughput_two_includes_gap_after_maintenance_one(self, mock_get_interval):
        mock_get_interval.side_effect = [('20.25', '21.50'), ('20.50', '23.25'),
                                         ('20.75', '23.00'), ('20.90', '22.75')]
        elapsed = nds_bench.get_throughput_time('/reports/throughput', 9, 2,
                                               maintenance_end=Decimal('15.00'))
        self.assertEqual(elapsed, 8.3)

    def test_full_driver_rejects_analyzed_load_report(self):
        with (Path(__file__).parent / "bench.yml").open() as config_file:
            config = nds_bench.yaml.safe_load(config_file)
        config['data_gen']['skip'] = True
        config['load_test']['skip'] = True
        for mode in ('table', 'all_columns'):
            with self.subTest(mode=mode):
                # An old config cannot pair an analyzed Hive Load with Delta/Iceberg phases.
                config['load_test']['analyze'] = mode
                report = mock_open(read_data=f'Load Statistics Mode: {mode}\n')
                with patch('builtins.open', report), \
                        self.assertRaisesRegex(ValueError, 'Load Statistics Mode set to none'):
                    nds_bench.run_full_bench(config)

    @patch("nds_bench.subprocess.run")
    def test_full_bench_validates_stream_count_before_starting(self, mock_run):
        with (Path(__file__).parent / "bench.yml").open() as config_file:
            config = nds_bench.yaml.safe_load(config_file)
        config["data_gen"]["skip"] = True
        config["generate_query_stream"]["num_streams"] = 11

        with self.assertRaisesRegex(ValueError, "num_streams must equal"):
            nds_bench.run_full_bench(config)

        mock_run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
