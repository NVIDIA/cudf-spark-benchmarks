# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Test cutoff helpers without starting a Spark process."""

import argparse
import datetime
from pathlib import Path
import contextlib
import io
from types import SimpleNamespace
import sys
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nds_power as driver


class FakePath:
    def __init__(self, path, filesystem):
        self.path = path
        self.filesystem = filesystem

    def getFileSystem(self, configuration):
        return self.filesystem

    def getName(self):
        return self.path.rsplit('/', 1)[-1]

    def toString(self):
        return self.path


def partition_session(entries, forbidden=()):
    filesystem = SimpleNamespace()
    layout = entries if isinstance(entries, dict) else {
        '/facts': entries,
        **{'/facts/' + name: [('part.parquet', False)] for name, directory in entries if directory}
    }

    def list_status(path):
        if path.path in forbidden:
            raise AssertionError('Future date partition must not be traversed: ' + path.path)
        return [
            SimpleNamespace(
                getPath=lambda name=name: FakePath(path.path + '/' + name, filesystem),
                isDirectory=lambda directory=directory: directory)
            for name, directory in layout.get(path.path, [])]

    filesystem.listStatus = list_status
    return SimpleNamespace(
        _jvm=SimpleNamespace(org=SimpleNamespace(apache=SimpleNamespace(
            hadoop=SimpleNamespace(fs=SimpleNamespace(
                Path=lambda path: FakePath(path, filesystem)))))),
        sparkContext=SimpleNamespace(_jsc=SimpleNamespace(hadoopConfiguration=lambda: None)))


class CutoffSelectionTest(unittest.TestCase):
    def test_cutoff_setup_time_covers_mapping_and_partition_selection_only_when_requested(self):
        for analyze in (False, True):
            for cutoff in (None, datetime.date(2001, 1, 2)):
                with self.subTest(analyze=analyze, cutoff=cutoff):
                    session = Mock()
                    session.conf.get.return_value = 'application-test'
                    session.catalog.currentDatabase.return_value = 'default'
                    session.catalog.tableExists.return_value = False
                    clock = [1000.0]

                    def map_dates(*args):
                        clock[0] += 0.125
                        return {}

                    def select_partitions(*args):
                        args[3]()
                        clock[0] += 0.250
                        return [('1', '/facts/date=1')]

                    with patch.object(driver.time, 'time', side_effect=lambda: clock[0]), \
                            patch.object(driver, '_date_key_mapping', side_effect=map_dates), \
                            patch.object(driver, '_partitions_at_cutoff', side_effect=select_partitions), \
                            patch.object(driver, '_create_data_source_table'), \
                            patch.object(driver, '_require_partition_files'), \
                            contextlib.redirect_stdout(io.StringIO()):
                        timings = driver.setup_tables(session, '/facts', 'parquet', False, [],
                                                      analyze_tables=analyze, cutoff_date=cutoff)
                    preparation = [row for row in timings if row[1] == 'Power Cutoff Setup Time']
                    self.assertEqual(preparation, [] if cutoff is None else
                                     [('application-test', 'Power Cutoff Setup Time', 1875)])

    def test_selects_cutoff_inclusively_and_keeps_null_partitions(self):
        entries = [('ss_sold_date_sk=3', True), ('_SUCCESS', False),
                   ('ss_sold_date_sk=1', True), ('.hidden', False),
                   ('ss_sold_date_sk=__HIVE_DEFAULT_PARTITION__', True),
                   ('ss_sold_date_sk=2', True)]
        dates = {key: datetime.date(2001, 1, key) for key in (1, 2, 3)}
        selected = driver._partitions_at_cutoff(
            partition_session(entries), '/facts', 'ss_sold_date_sk', lambda: dates,
            datetime.date(2001, 1, 2))
        self.assertEqual(selected, [
            ({'ss_sold_date_sk': '1'}, '/facts/ss_sold_date_sk=1'),
            ({'ss_sold_date_sk': '2'}, '/facts/ss_sold_date_sk=2'),
            ({'ss_sold_date_sk': '__HIVE_DEFAULT_PARTITION__'},
             '/facts/ss_sold_date_sk=__HIVE_DEFAULT_PARTITION__')])

    def test_calendar_date_partitions_need_no_date_dimension(self):
        entries = [('order_date=2001-01-03', True), ('order_date=2001-01-01', True),
                   ('order_date=__HIVE_DEFAULT_PARTITION__', True),
                   ('order_date=2001-01-02', True)]
        def unexpected_mapping():
            raise AssertionError('Calendar dates do not require a date dimension')
        selected = driver._partitions_at_cutoff(
            partition_session(entries), '/facts', 'order_date', unexpected_mapping,
            datetime.date(2001, 1, 2))
        self.assertEqual(selected, [
            ({'order_date': '2001-01-01'}, '/facts/order_date=2001-01-01'),
            ({'order_date': '2001-01-02'}, '/facts/order_date=2001-01-02'),
            ({'order_date': '__HIVE_DEFAULT_PARTITION__'},
             '/facts/order_date=__HIVE_DEFAULT_PARTITION__')])

    def test_future_date_directories_are_not_traversed(self):
        null = '__HIVE_DEFAULT_PARTITION__'
        for calendar in (False, True):
            values = ['2001-01-01', '2001-01-02', '2001-01-03'] if calendar else ['1', '2', '3']
            for position in ('only', 'first', 'second'):
                with self.subTest(calendar=calendar, date_position=position):
                    layout, forbidden, expected = {}, set(), []
                    for value in [*values, null]:
                        columns = [('day', value)]
                        if position == 'first':
                            columns.append(('region', 'west'))
                        elif position == 'second':
                            columns.insert(0, ('region', 'west'))
                        path = '/facts'
                        for column, partition_value in columns:
                            name = column + '=' + partition_value
                            children = layout.setdefault(path, [])
                            if (name, True) not in children:
                                children.append((name, True))
                            path += '/' + name
                            if column == 'day' and value == values[2]:
                                forbidden.add(path)
                        layout[path] = [('part.parquet', False)]
                        if value != values[2]:
                            expected.append((dict(columns), path))

                    def date_keys():
                        if calendar:
                            raise AssertionError('Calendar dates do not require a date dimension')
                        return {key: datetime.date(2001, 1, key) for key in (1, 2, 3)}

                    selected = driver._partitions_at_cutoff(
                        partition_session(layout, forbidden), '/facts', 'day', date_keys,
                        datetime.date(2001, 1, 2))
                    self.assertEqual(selected, sorted(expected, key=lambda partition: partition[1]))

    def test_declared_layout_stops_at_leaves_and_checks_the_column_order(self):
        for columns in (['day'], ['day', '_tenant'], ['_tenant', 'day']):
            with self.subTest(columns=columns):
                layout, leaves = {}, set()
                for day in ('2001-01-01', '2001-01-03'):
                    path = '/facts'
                    for column in columns:
                        name = column + '=' + (day if column == 'day' else 'a')
                        entries = layout.setdefault(path, [])
                        if (name, True) not in entries:
                            entries.append((name, True))
                        path += '/' + name
                    leaves.add(path)
                selected = driver._partitions_at_cutoff(
                    partition_session(layout, leaves), '/facts', 'day', lambda: {},
                    datetime.date(2001, 1, 2), columns)
                self.assertEqual([list(specification) for specification, _ in selected], [columns])
                self.assertEqual(selected[0][0]['day'], '2001-01-01')
        with self.assertRaisesRegex(ValueError, 'declared order'):
            driver._partitions_at_cutoff(
                partition_session({'/facts': [('region=west', True)]}), '/facts', 'day',
                lambda: {}, datetime.date(2001, 1, 2), ['day', 'region'])

    def test_discovery_ignores_empty_branches_and_preserves_spark_partition_decoding(self):
        layout = {'/facts': [('region=empty', True), ('region=%C3%A9', True)],
                  '/facts/region=empty': [],
                  '/facts/region=%C3%A9': [('day=2001-01-01', True)],
                  '/facts/region=%C3%A9/day=2001-01-01': [('part.parquet', False)]}
        self.assertEqual(driver._partitions_at_cutoff(
            partition_session(layout), '/facts', 'day', lambda: {}, datetime.date(2001, 1, 2)),
            [({'region': 'Ã©', 'day': '2001-01-01'},
              '/facts/region=%C3%A9/day=2001-01-01')])
        with self.assertRaisesRegex(ValueError, 'No dated partitions'):
            driver._partitions_at_cutoff(
                partition_session({'/facts': [('day=2001-01-01', True)]}), '/facts', 'day',
                lambda: {}, datetime.date(2001, 1, 2))

    def test_rejects_invalid_layout_dates_and_null_only_selection(self):
        for entry, message in [
                (('other_column=1', True), 'Unexpected partition layout'),
                (('ss_sold_date_sk=1', False), 'Unexpected partition layout'),
                (('ss_sold_date_sk=invalid', True), 'Invalid date partition'),
                (('ss_sold_date_sk=99', True), 'missing from date_dim')]:
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, message):
                driver._partitions_at_cutoff(
                    partition_session([entry]), '/facts', 'ss_sold_date_sk',
                    lambda: {1: datetime.date(2001, 1, 1)}, datetime.date(2001, 1, 2))
        for column in driver.DATE_PARTITION_COLUMNS.values():
            for entries in ([], [(column + '=__HIVE_DEFAULT_PARTITION__', True)],
                            [(column + '=1', True),
                             (column + '=__HIVE_DEFAULT_PARTITION__', True)]):
                with self.subTest(column=column, entries=entries), self.assertRaisesRegex(
                        ValueError, 'No dated partitions at or before 2001-01-02'):
                    driver._partitions_at_cutoff(
                        partition_session(entries), '/facts', column,
                        lambda: {1: datetime.date(2001, 1, 3)}, datetime.date(2001, 1, 2))

    def test_parser_errors_are_readable_and_mapping_rejects_bad_dates(self):
        self.assertEqual(driver._parse_cutoff_date('2001-01-02'), datetime.date(2001, 1, 2))
        for value in ('not-a-date', '2001-02-30'):
            with self.subTest(value=value), self.assertRaisesRegex(
                    argparse.ArgumentTypeError, 'YYYY-MM-DD'):
                driver._parse_cutoff_date(value)
        for rows in [
                [SimpleNamespace(d_date_sk=None, d_date=datetime.date(2001, 1, 1))],
                [SimpleNamespace(d_date_sk=1, d_date=None)],
                [SimpleNamespace(d_date_sk='1', d_date=datetime.date(2001, 1, 1))],
                [SimpleNamespace(d_date_sk=True, d_date=datetime.date(2001, 1, 1))],
                [SimpleNamespace(d_date_sk=1, d_date=datetime.datetime(2001, 1, 1))],
                [SimpleNamespace(d_date_sk=1, d_date='2001-01-01'),
                 SimpleNamespace(d_date_sk=1, d_date='2001-01-02')]]:
            selected = SimpleNamespace(collect=lambda: rows)
            reader = SimpleNamespace(load=lambda path: SimpleNamespace(select=lambda *cols: selected))
            session = SimpleNamespace(read=SimpleNamespace(format=lambda fmt: reader))
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                driver._date_key_mapping(session, '/data', 'parquet', False)

    def test_unsupported_inputs_require_classic_spark_before_construction(self):
        for options in ({'input_format': 'iceberg'}, {'input_format': 'delta'},
                        {'hive_external': True}, {'spark_connect': 'sc://server'}):
            with self.subTest(options=options), self.assertRaisesRegex(
                    ValueError, 'classic Spark session'):
                driver.run_query_stream(
                    input_prefix='/data', property_file=None, query_dict={},
                    time_log_output_path='times.csv', extra_time_log_output_path=None,
                    sub_queries=None, sub_query_patterns=None, warmup_iterations=0,
                    iterations=1, plan_types=None, **options,
                    cutoff_date=datetime.date(2001, 1, 2))


if __name__ == '__main__':
    unittest.main()
