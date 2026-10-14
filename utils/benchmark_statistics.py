# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import os
import time


def analyze_table(session, mode, table_name):
    if mode not in ('table', 'all_columns'):
        raise ValueError('active analysis must be table or all_columns')
    suffix = ' FOR ALL COLUMNS' if mode == 'all_columns' else ''
    statement = 'ANALYZE TABLE `' + table_name.replace('`', '``') + '` COMPUTE STATISTICS' + suffix
    print(statement)
    session.sql(statement)


def analyze_catalog(session, mode, table_names, summary_folder):
    if mode in (None, 'none'):
        return {'mode': 'none', 'duration_ms': 0, 'tables': []}
    if mode not in ('table', 'all_columns'):
        raise ValueError('analyze must be none, table, or all_columns')
    timings = []
    start = time.perf_counter_ns()
    for table in table_names:
        before = time.perf_counter_ns()
        analyze_table(session, mode, table)
        timings.append({'table': table, 'duration_ms': (time.perf_counter_ns() - before) / 1e6})
    report = {
        'mode': mode,
        'duration_ms': (time.perf_counter_ns() - start) / 1e6,
        'tables': timings,
    }
    if summary_folder:
        cost_folder = os.path.join(summary_folder, 'statistics')
        os.makedirs(cost_folder, exist_ok=True)
        with open(os.path.join(cost_folder, 'analyze-cost.json'), 'w') as output:
            json.dump(report, output, indent=2)
    return report
