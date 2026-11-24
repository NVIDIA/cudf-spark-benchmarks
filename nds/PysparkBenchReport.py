#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-FileCopyrightText: Copyright (c) 2022-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#
# -----
#
# Certain portions of the contents of this file are derived from TPC-DS version 3.2.0
# (retrieved from www.tpc.org/tpc_documents_current_versions/current_specifications5.asp).
# Such portions are subject to copyrights held by Transaction Processing Performance Council (“TPC”)
# and licensed under the TPC EULA (a copy of which accompanies this file as “TPC EULA” and is also
# available at http://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp) (the “TPC EULA”).
#
# You may not use this file except in compliance with the TPC EULA.
# DISCLAIMER: Portions of this file is derived from the TPC-DS Benchmark and as such any results
# obtained using this file are not comparable to published TPC-DS Benchmark results, as the results
# obtained from using this file do not comply with the TPC-DS Benchmark.
#

import gc
import json
import os
import time
import traceback
from typing import Callable

from pyspark.sql import SparkSession

class PysparkBenchReport:
    """Class to generate json summary report for a benchmark
    """
    def __init__(self, spark_session: SparkSession, query_name) -> None:
        self.spark_session = spark_session
        self.summary = {
            'env': {
                'envVars': {},
                'sparkConf': {},
                'sparkVersion': None
            },
            'queryStatus': [],
            'exceptions': [],
            'startTime': None,
            'queryTimes': [],
            'query': query_name,
        }
        # Wall-clock start and end of each collection, in nanoseconds, for the Power interval.
        self.python_gc_spans = []

    def _is_spark_400_or_later(self):
        return self.spark_session.version >= "4.0.0"

    def _register_python_listener(self):
        # Register PythonListener
        if self._is_spark_400_or_later():
            # is_remote is added starting from 4.0.0
            from pyspark.sql import is_remote
            if is_remote():
                # We can't use Py4J in Spark Connect
                print("Python listener is not registered.")
                return None

        listener = None
        try:
            import python_listener
            listener = python_listener.PythonListener()
            listener.register()
        except Exception as e:
            print("Not found com.nvidia.spark.rapids.listener.Manager", str(e))
            listener = None
        return listener

    def _get_spark_conf(self):
        if self._is_spark_400_or_later():
            from pyspark.sql import is_remote
            if is_remote():
                get_all = getattr(self.spark_session.conf, 'getAll', None)
                return get_all() if callable(get_all) else (get_all or [])

        try:
            return self.spark_session.sparkContext._conf.getAll()
        except Exception:
            get_all = getattr(self.spark_session.conf, 'getAll', None)
            return get_all() if callable(get_all) else (get_all or [])


    def report_on(self, fn: Callable, warmup_iterations = 0, iterations = 1, *args,
                  python_gc_after_query=False):
        """Record a function for its running environment, running status etc. and exclude sentive
        information like tokens, secret and password Generate summary in dict format for it.

        Args:
            fn (Callable): a function to be recorded
            python_gc_after_query (bool): run Python garbage collection after each warmup and
                timed call, once its end time is taken, and record each collection's duration

        Returns:
            dict: summary of the fn
        """
        spark_conf = dict(self._get_spark_conf())
        env_vars = dict(os.environ)
        redacted = ["TOKEN", "SECRET", "PASSWORD"]
        filtered_env_vars = dict((k, env_vars[k]) for k in env_vars.keys() if not (k in redacted))
        self.summary['env']['envVars'] = filtered_env_vars
        self.summary['env']['sparkConf'] = spark_conf
        self.summary['env']['sparkVersion'] = self.spark_session.version
        listener = self._register_python_listener()
        if listener is not None:
            print("TaskFailureListener is registered.")
        if python_gc_after_query:
            self.summary['pythonGcTimes'] = []
        # warmup
        for i in range(0, warmup_iterations):
            warmup_failed = False
            try:
                fn(*args)
            except Exception as e:
                print('ERROR WHILE WARMUP BEGIN')
                print(e)
                traceback.print_tb(e.__traceback__)
                print('ERROR WHILE WARMUP END')
                warmup_failed = True
            self._collect_python_garbage(python_gc_after_query)
            if warmup_failed:
                break

        start_time = int(time.time() * 1000)
        self.summary['startTime'] = start_time
        # run the query
        for i in range(0, iterations):
            try:
                start_time = int(time.time() * 1000)
                fn(*args)
                end_time = int(time.time() * 1000)
                if listener and len(listener.failures) != 0:
                    self.summary['queryStatus'].append("CompletedWithTaskFailures")
                else:
                    self.summary['queryStatus'].append("Completed")
            except Exception as e:
                # print the exception to ease debugging
                print('ERROR BEGIN')
                print(e)
                traceback.print_tb(e.__traceback__)
                print('ERROR END')
                end_time = int(time.time() * 1000)
                self.summary['queryStatus'].append("Failed")
                self.summary['exceptions'].append(str(e))
            finally:
                self.summary['queryTimes'].append(end_time - start_time)
            self._collect_python_garbage(python_gc_after_query)
        if listener is not None:
            listener.unregister()
        return self.summary

    def _collect_python_garbage(self, enabled):
        """Collect Python reference cycles, whose Py4J proxies keep finished JVM query plans
        reachable. Call it outside an except clause, whose traceback keeps the failed call's
        frames reachable. Time it on the wall clock, which times the queries and the Power
        interval."""
        if enabled:
            start = time.time_ns()
            gc.collect()
            end = time.time_ns()
            self.summary['pythonGcTimes'].append(round((end - start) / 1_000_000, 3))
            self.python_gc_spans.append((start, end))

    def write_summary(self, prefix=""):
        """_summary_

        Args:
            query_name (str): name of the query
            prefix (str, optional): prefix for the output json summary file. Defaults to "".
        """
        # Power BI side is retrieving some information from the summary file name, so keep this file
        # name format for pipeline compatibility
        filename = prefix + '-' + self.summary['query'] + '-' +str(self.summary['startTime']) + '.json'
        self.summary['filename'] = filename
        with open(filename, "w") as f:
            json.dump(self.summary, f, indent=2)

    def is_success(self):
        """Check if the query succeeded, queryStatus == Completed
        """
        return self.summary['queryStatus'][0] == 'Completed'
