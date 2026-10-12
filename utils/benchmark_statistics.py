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
import tempfile
import time
import uuid

from pyspark.sql import SparkSession


def isolated_session(builder, app_name, mode, summary_folder, input_format):
    if mode not in ('none', 'table', 'column'):
        raise ValueError('analyze must be none, table, or column')
    if not summary_folder:
        raise ValueError('--analyze requires --json_summary_folder')
    if input_format not in ('parquet', 'orc', 'avro', 'csv', 'json'):
        raise ValueError('--analyze requires file-backed benchmark inputs')
    if SparkSession.getActiveSession() is not None:
        raise ValueError('--analyze requires a fresh Spark driver session')
    identity = uuid.uuid4().hex
    warehouse = 'file:' + os.path.join(tempfile.gettempdir(), 'benchmark-catalog-' + identity)
    session = (builder.config('spark.sql.catalogImplementation', 'in-memory')
               .config('spark.sql.warehouse.dir', warehouse)
               .appName(app_name).getOrCreate())
    # getOrCreate can reuse a default session even when none is active.
    if (session.conf.get('spark.sql.catalogImplementation') != 'in-memory' or
            session.conf.get('spark.sql.warehouse.dir') != warehouse):
        raise ValueError('--analyze did not create an isolated catalog')
    if (session.conf.get('spark.sql.defaultCatalog', 'spark_catalog') != 'spark_catalog' or
            session.conf.get('spark.sql.catalog.spark_catalog', '')):
        raise ValueError('--analyze cannot use a custom catalog')
    database = 'benchmark_' + identity
    session.sql('CREATE DATABASE ' + database)
    session.catalog.setCurrentDatabase(database)
    return session


def analyze_catalog(session, mode, table_names, summary_folder):
    timings = []
    start = time.perf_counter_ns()
    if mode != 'none':
        suffix = ' FOR ALL COLUMNS' if mode == 'column' else ''
        for table in table_names:
            before = time.perf_counter_ns()
            session.sql('ANALYZE TABLE `' + table + '` COMPUTE STATISTICS' + suffix)
            timings.append({'table': table, 'duration_ms': (time.perf_counter_ns() - before) / 1e6})
    report = {
        'mode': mode,
        'duration_ms': (time.perf_counter_ns() - start) / 1e6 if mode != 'none' else 0,
        'tables': timings,
    }
    cost_folder = os.path.join(summary_folder, 'statistics')
    os.makedirs(cost_folder, exist_ok=True)
    with open(os.path.join(cost_folder, 'analyze-cost.json'), 'w') as output:
        json.dump(report, output, indent=2)
    return report
