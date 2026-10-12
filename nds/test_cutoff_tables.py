# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES.
# All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Check cutoff selection and guards without starting Spark."""

import ast
import datetime
import inspect
from pathlib import Path
from types import SimpleNamespace
import unittest


def cutoff_functions():
    source = Path(__file__).with_name('nds_power.py')
    names = {'_parse_cutoff_date', '_date_key_mapping', '_partitions_at_cutoff',
             'run_query_stream'}
    nodes = [node for node in ast.parse(source.read_text()).body
             if isinstance(node, ast.FunctionDef) and node.name in names]
    namespace = {'datetime': datetime}
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(source), 'exec'), namespace)
    return namespace


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


def partition_session(entries):
    filesystem = SimpleNamespace()
    filesystem.listStatus = lambda path: [
        SimpleNamespace(getPath=lambda name=name: FakePath('/facts/' + name, filesystem),
                        isDirectory=lambda directory=directory: directory)
        for name, directory in entries]
    return SimpleNamespace(
        _jvm=SimpleNamespace(org=SimpleNamespace(apache=SimpleNamespace(
            hadoop=SimpleNamespace(fs=SimpleNamespace(
                Path=lambda path: FakePath(path, filesystem)))))),
        sparkContext=SimpleNamespace(_jsc=SimpleNamespace(hadoopConfiguration=lambda: None)))


class CutoffSelectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.functions = cutoff_functions()

    def test_selects_cutoff_inclusively_and_keeps_null_partitions(self):
        entries = [('ss_sold_date_sk=3', True), ('_SUCCESS', False),
                   ('ss_sold_date_sk=1', True), ('.hidden', False),
                   ('ss_sold_date_sk=__HIVE_DEFAULT_PARTITION__', True),
                   ('ss_sold_date_sk=2', True)]
        dates = {key: datetime.date(2001, 1, key) for key in (1, 2, 3)}
        selected = self.functions['_partitions_at_cutoff'](
            partition_session(entries), '/facts', 'ss_sold_date_sk', dates,
            datetime.date(2001, 1, 2))
        self.assertEqual(selected, [
            ('1', '/facts/ss_sold_date_sk=1'), ('2', '/facts/ss_sold_date_sk=2'),
            ('__HIVE_DEFAULT_PARTITION__', '/facts/ss_sold_date_sk=__HIVE_DEFAULT_PARTITION__')])

    def test_invalid_partition_layout_and_unknown_dates_fail(self):
        select = self.functions['_partitions_at_cutoff']
        for entry, message in [
                (('other_column=1', True), 'Unexpected partition layout'),
                (('ss_sold_date_sk=1', False), 'Unexpected partition layout'),
                (('ss_sold_date_sk=invalid', True), 'Invalid date partition'),
                (('ss_sold_date_sk=99', True), 'missing from date_dim')]:
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, message):
                select(partition_session([entry]), '/facts', 'ss_sold_date_sk',
                       {1: datetime.date(2001, 1, 1)}, datetime.date(2001, 1, 2))
        with self.assertRaisesRegex(ValueError, 'No partitions'):
            select(partition_session([('ss_sold_date_sk=1', True)]), '/facts',
                   'ss_sold_date_sk', {1: datetime.date(2001, 1, 3)},
                   datetime.date(2001, 1, 2))

    def test_date_parser_and_mapping_reject_invalid_or_ambiguous_dates(self):
        parse = self.functions['_parse_cutoff_date']
        self.assertEqual(parse('2001-01-02'), datetime.date(2001, 1, 2))
        for value in ('not-a-date', '2001-02-30'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse(value)
        mapping = self.functions['_date_key_mapping']
        for rows in [
                [SimpleNamespace(d_date_sk=None, d_date=datetime.date(2001, 1, 1))],
                [SimpleNamespace(d_date_sk=1, d_date=None)],
                [SimpleNamespace(d_date_sk=1, d_date='2001-01-01'),
                 SimpleNamespace(d_date_sk=1, d_date='2001-01-02')]]:
            selected = SimpleNamespace(collect=lambda: rows)
            reader = SimpleNamespace(load=lambda path: SimpleNamespace(select=lambda *cols: selected))
            session = SimpleNamespace(read=SimpleNamespace(format=lambda fmt: reader))
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                mapping(session, '/data', 'parquet', False)

    def test_unsupported_combinations_fail_before_session_construction(self):
        run = self.functions['run_query_stream']
        required = {name: None for name, parameter in inspect.signature(run).parameters.items()
                    if parameter.default is inspect.Parameter.empty}
        for options in ({'input_format': 'iceberg'}, {'input_format': 'delta'},
                        {'hive_external': True}, {'spark_connect': 'sc://server'},
                        {'analyze_tables': True}):
            with self.subTest(options=options), self.assertRaisesRegex(
                    ValueError, '--cutoff_date requires'):
                run(**required, cutoff_date=datetime.date(2001, 1, 2), **options)


if __name__ == '__main__':
    unittest.main()
