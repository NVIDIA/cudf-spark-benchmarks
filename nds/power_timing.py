# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Power report timing contract, independent of Spark."""

import csv
from decimal import Decimal, ROUND_CEILING
import re
import time


TIMING_VERSION = 1

# TPC-DS 3.2.0 Appendix D, Stream 0. Throughput permutations come from dsqgen.
STREAM_ZERO_ORDER = (
    96, 7, 75, 44, 39, 80, 32, 19, 25, 78, 86, 1, 91, 21, 43, 27, 94, 45,
    58, 64, 36, 33, 46, 62, 16, 10, 63, 69, 60, 59, 37, 98, 85, 70, 67, 28,
    81, 97, 66, 90, 17, 47, 95, 92, 3, 51, 35, 49, 9, 31, 11, 93, 29, 38,
    22, 89, 15, 6, 52, 50, 42, 41, 8, 12, 20, 88, 82, 23, 14, 57, 65, 71,
    34, 48, 30, 74, 87, 77, 73, 84, 54, 55, 56, 2, 26, 40, 72, 53, 79, 18,
    13, 24, 4, 99, 68, 83, 61, 5, 76,
)


class QueryTimer:
    """First SQL submission through last result receipt, including intervening work."""

    def __init__(self):
        self.start_ns = None
        self.end_ns = None
        self.start_tick = None
        self.end_tick = None
        self.query_tick = None
        self.work_ns = 0

    def start(self):
        self.query_tick = time.perf_counter_ns()
        if self.start_ns is None:
            self.start_ns = time.time_ns()
            self.start_tick = self.query_tick

    def finish(self):
        self.end_tick = time.perf_counter_ns()
        self.work_ns += self.end_tick - self.query_tick
        self.end_ns = time.time_ns()

    @property
    def clock_consistent(self):
        # A wall-clock correction must not make the Power duration and the
        # endpoints used for throughput disagree. Allow 1 ms for clock reads.
        return (self.start_ns is not None and self.end_ns is not None and
                abs((self.end_ns - self.start_ns) -
                    (self.end_tick - self.start_tick)) <= 1_000_000)

    @property
    def work_ms(self):
        return self.work_ns / 1_000_000

    @property
    def elapsed_ms(self):
        if self.start_tick is None or self.end_tick is None:
            return 0.0
        return (self.end_tick - self.start_tick) / 1_000_000

    @property
    def start_seconds(self):
        return self.start_ns / 1_000_000_000 if self.start_ns is not None else 0.0

    @property
    def end_seconds(self):
        return self.end_ns / 1_000_000_000 if self.end_ns is not None else 0.0


def round_seconds(seconds):
    """TPC-DS 3.2.0 section 7.1.16, applied after subtraction/conversion."""
    value = Decimal(str(seconds))
    if not value.is_finite() or value < 0:
        raise ValueError('Elapsed seconds must be finite and nonnegative')
    return float(value.quantize(Decimal('0.1'), rounding=ROUND_CEILING))


def stream_number(queries):
    """Check the generated 99-template stream, including its four split queries.

    This checks structure, not SQL semantics or generator provenance. Approved
    template variants are conservatively unsupported by the score contract.
    """
    groups = []
    stream = None
    for name, sql in queries.items():
        match = re.match(
            r'\s*-- start query\s*(\d+)\s+in stream\s+(\d+)\s+'
            r'using template query(\d+)(?:_benchmark(\d+))?\.tpl\b', sql)
        if match is None:
            return -1
        ordinal, current_stream, template = map(int, match.groups()[:3])
        # gen_sql_from_stream rewrites template headers for each SQL statement.
        part = match.group(4)
        if part is not None and int(part) != (2 if name.endswith('_part2') else 1):
            return -1
        if stream is None:
            stream = current_stream
        if current_stream != stream:
            return -1
        if not groups or groups[-1][0] != ordinal:
            groups.append((ordinal, template, []))
        if template != groups[-1][1]:
            return -1
        groups[-1][2].append(name)
    if [group[0] for group in groups] != list(range(1, 100)):
        return -1
    if sorted(group[1] for group in groups) != list(range(1, 100)):
        return -1
    if stream == 0 and tuple(group[1] for group in groups) != STREAM_ZERO_ORDER:
        return -1
    for _, template, names in groups:
        expected = ([f'query{template}_part1', f'query{template}_part2']
                    if template in (14, 23, 24, 39) else [f'query{template}'])
        if names != expected:
            return -1
    return stream


def read_score_report(path, expected_stream):
    """Reject old/extended/failed reports even when execution phases are skipped."""
    with open(path, newline='') as report:
        rows = list(csv.reader(report))
    values = {}
    required = {'NDS Timing Version', 'NDS Metric Eligible', 'Query Stream',
                'Power Start Time', 'Power End Time', 'Power Test Time'}
    for row in rows[1:]:
        if len(row) == 3 and row[1] in required:
            if row[1] in values:
                raise ValueError(f'Duplicate {row[1]} in {path}')
            values[row[1]] = row[2]
    try:
        fields = {key: Decimal(values[key]) for key in required}
        if any(not value.is_finite() for value in fields.values()):
            raise ValueError('nonfinite field')
        if (fields['NDS Timing Version'] != TIMING_VERSION or
                fields['NDS Metric Eligible'] != 1 or
                fields['Query Stream'] != expected_stream or
                fields['Power Start Time'] <= 0 or
                fields['Power End Time'] < fields['Power Start Time'] or
                fields['Power Test Time'] <= 0 or
                abs((fields['Power End Time'] - fields['Power Start Time']) * 1000 -
                    fields['Power Test Time']) > 1):
            raise ValueError('incompatible timing contract')
    except (KeyError, ValueError, ArithmeticError) as error:
        raise ValueError(
            f'{path} is not an eligible NDS query-stream report for stream '
            f'{expected_stream}; rerun with the current driver, a complete generated '
            'stream, and default execution options. ANALYZE in Power must not be '
            'used to bypass database-load accounting.') from error
    return fields
