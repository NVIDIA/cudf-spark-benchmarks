# Copyright (c) 2026, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import unittest
from unittest.mock import call, patch

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
        self.assertEqual([1, 2, 3, 4],
                         nds_bench.get_stream_range(9, 1))
        self.assertEqual([5, 6, 7, 8],
                         nds_bench.get_stream_range(9, 2))

    def test_refresh_run_ranges(self):
        self.assertEqual([1, 2], nds_bench.get_refresh_range(9, 1))
        self.assertEqual([3, 4], nds_bench.get_refresh_range(9, 2))

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
        nds_bench.run_data_gen("100", "4", "/data/raw", "hdfs", 9)

        expected_calls = [
            call(["python3", "nds_gen_data.py", "hdfs", "100", "4",
                  "/data/raw", "--overwrite_output"], check=True)
        ]
        expected_calls.extend(
            call(["python3", "nds_gen_data.py", "hdfs", "100", "4",
                  f"/data/raw_{i}", "--overwrite_output", "--update", str(i)],
                 check=True)
            for i in range(1, 5)
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

    @patch("nds_bench.get_refresh_time")
    def test_maintenance_time_reads_only_its_refresh_reports(
            self, mock_get_refresh_time):
        mock_get_refresh_time.side_effect = [1.01, 2.01]

        result = nds_bench.get_maintenance_time("/reports/maintenance", 9, 2)

        self.assertEqual(3.1, result)
        self.assertEqual(
            [call("/reports/maintenance_3.csv"),
             call("/reports/maintenance_4.csv")],
            mock_get_refresh_time.call_args_list)


if __name__ == "__main__":
    unittest.main()
