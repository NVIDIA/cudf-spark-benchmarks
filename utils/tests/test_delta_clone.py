# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Tests for run-scoped managed Delta shallow clones."""

import builtins
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from delta_clone import DeltaCloneScope, new_run_session, _validate_clone_warehouse


class DeltaCloneScopeTest(unittest.TestCase):
    def _warehouse_session(self, master, warehouse, scheme, allow_local='false'):
        spark = Mock()
        spark.sparkContext.master = master
        spark.conf.get.side_effect = lambda key, *default: {
            'spark.sql.warehouse.dir': warehouse,
            'spark.benchmarks.delta.allowLocalWarehouse': allow_local,
        }[key]
        path = spark._jvm.org.apache.hadoop.fs.Path.return_value
        path.toUri.return_value.getScheme.return_value = scheme
        return spark

    def test_nonlocal_local_warehouse_fails_before_catalog_mutation(self):
        for master in ('spark://cluster:7077', 'yarn', 'k8s://cluster', 'local-cluster[2,1,1024]'):
            with self.subTest(master=master):
                spark = self._warehouse_session(master, 'file:/driver/warehouse', 'file')
                with self.assertRaisesRegex(ValueError, 'spark.sql.warehouse.dir=.*local filesystem'):
                    DeltaCloneScope(spark, 'nds_delta_run')
                spark.sql.assert_not_called()
                spark.catalog.setCurrentDatabase.assert_not_called()

    def test_scheme_less_warehouse_uses_hadoop_default_filesystem(self):
        for scheme in ('file', 'hdfs'):
            with self.subTest(scheme=scheme):
                spark = self._warehouse_session('yarn', '/warehouse', None)
                path = spark._jvm.org.apache.hadoop.fs.Path.return_value
                path.getFileSystem.return_value.getUri.return_value.getScheme.return_value = scheme
                if scheme == 'file':
                    with self.assertRaisesRegex(ValueError, 'shared warehouse'):
                        _validate_clone_warehouse(spark)
                else:
                    _validate_clone_warehouse(spark)

    def test_remote_warehouse_does_not_require_a_filesystem_client(self):
        for scheme in ('hdfs', 'viewfs', 's3a', 'abfss'):
            with self.subTest(scheme=scheme):
                spark = self._warehouse_session('yarn', scheme + '://storage/warehouse', scheme)
                _validate_clone_warehouse(spark)
                spark._jvm.org.apache.hadoop.fs.Path.return_value.getFileSystem.assert_not_called()

    def test_local_masters_keep_local_warehouse_support(self):
        for master in ('local', 'local[2]', 'local[*]'):
            with self.subTest(master=master):
                spark = self._warehouse_session(master, 'file:/warehouse', 'file')
                _validate_clone_warehouse(spark)
                spark.conf.get.assert_not_called()

    def test_local_warehouse_requires_explicit_true_override(self):
        for value in ('false', '', '1', 'TRUE'):
            with self.subTest(value=value):
                spark = self._warehouse_session('spark://cluster:7077', 'file:/warehouse',
                                                'file', value)
                if value == 'TRUE':
                    with self.assertLogs('delta_clone', level='WARNING') as logs:
                        _validate_clone_warehouse(spark)
                    self.assertIn('every executor share this storage', '\n'.join(logs.output))
                else:
                    with self.assertRaisesRegex(ValueError, 'allowLocalWarehouse=true'):
                        _validate_clone_warehouse(spark)

    def test_classic_session_does_not_import_optional_connect_dependencies(self):
        spark = Mock()
        entries = spark._jsparkSession.conf.return_value.getAll.return_value.iterator.return_value
        entries.hasNext.return_value = False
        original_import = builtins.__import__

        def import_without_connect(name, *args, **kwargs):
            if name.startswith('pyspark.sql.connect'):
                raise ValueError('numpy.dtype size changed')
            return original_import(name, *args, **kwargs)

        with patch('builtins.__import__', side_effect=import_without_connect):
            run_session = new_run_session(spark, {})

        self.assertIs(run_session, spark.newSession.return_value)
        spark.newSession.assert_called_once_with()

    def test_connect_is_rejected_before_creating_clones(self):
        try:
            from pyspark.sql.connect.session import SparkSession as ConnectSparkSession
        except ImportError:
            self.skipTest('Spark Connect client dependencies are not installed')

        class CustomConnectSparkSession(ConnectSparkSession):
            pass

        # Construct real Connect clients without starting or contacting a server.
        for session_type in (ConnectSparkSession, CustomConnectSparkSession):
            with self.subTest(session_type=session_type):
                spark = session_type('sc://localhost:1')
                try:
                    with patch.object(spark, 'sql') as sql:
                        with self.assertRaisesRegex(ValueError, 'require a classic Spark session'):
                            new_run_session(spark, {})
                        sql.assert_not_called()
                finally:
                    spark.client.close()

    @patch('delta_clone.uuid.uuid4')
    def test_clone_uses_unique_managed_database_and_quoted_source_path(self, uuid4):
        uuid4.return_value.hex = '0123456789abcdef'
        spark = Mock()
        spark.catalog.currentDatabase.return_value = 'default'

        scope = DeltaCloneScope(spark, 'nds_delta_run')
        scope.clone_table('abfss://container/root`name/customer', 'customer`copy')
        scope.close()
        scope.close()

        self.assertEqual(scope.database_name, 'nds_delta_run_0123456789abcdef')
        self.assertEqual(spark.catalog.setCurrentDatabase.call_args_list, [
            call('nds_delta_run_0123456789abcdef'),
            call('default'),
        ])
        spark.catalog.dropTempView.assert_not_called()
        self.assertEqual(spark.sql.call_args_list, [
            call('CREATE DATABASE `nds_delta_run_0123456789abcdef`'),
            call('CREATE TABLE `nds_delta_run_0123456789abcdef`.`customer``copy` '
                 'SHALLOW CLONE delta.`abfss://container/root``name/customer`'),
            call('DROP DATABASE `nds_delta_run_0123456789abcdef` CASCADE'),
        ])

    @patch('delta_clone.uuid.uuid4')
    def test_context_restores_database_and_drops_clones_after_failure(self, uuid4):
        uuid4.return_value.hex = 'fedcba9876543210'
        spark = Mock()
        spark.catalog.currentDatabase.return_value = 'benchmark'

        with self.assertRaisesRegex(RuntimeError, 'query failed'):
            with DeltaCloneScope(spark, 'nds_h_delta_run'):
                raise RuntimeError('query failed')

        self.assertEqual(spark.catalog.setCurrentDatabase.call_args_list, [
            call('nds_h_delta_run_fedcba9876543210'),
            call('benchmark'),
        ])
        self.assertEqual(spark.sql.call_args_list, [
            call('CREATE DATABASE `nds_h_delta_run_fedcba9876543210`'),
            call('DROP DATABASE `nds_h_delta_run_fedcba9876543210` CASCADE'),
        ])

    def test_cleanup_failure_preserves_run_error_and_allows_retry(self):
        spark = Mock()
        spark.catalog.currentDatabase.return_value = 'default'
        scope = DeltaCloneScope(spark, 'nds_delta_run')
        spark.sql.side_effect = RuntimeError('drop failed')
        query_error = RuntimeError('original query failed')

        with self.assertLogs('delta_clone', level='WARNING') as logs:
            with self.assertRaises(RuntimeError) as raised:
                with scope:
                    raise query_error
        self.assertIs(raised.exception, query_error)
        self.assertIn(scope.database_name, '\n'.join(logs.output))
        self.assertIn('drop failed', '\n'.join(logs.output))

        spark.sql.side_effect = None
        scope.close()
        self.assertEqual(spark.sql.call_args_list[-2:], [
            call('DROP DATABASE `{}` CASCADE'.format(scope.database_name)),
            call('DROP DATABASE `{}` CASCADE'.format(scope.database_name)),
        ])

    def test_restore_failure_still_attempts_drop_after_success(self):
        spark = Mock()
        spark.catalog.currentDatabase.return_value = 'default'
        scope = DeltaCloneScope(spark, 'nds_delta_run')
        spark.catalog.setCurrentDatabase.side_effect = RuntimeError('restore failed')

        with self.assertLogs('delta_clone', level='WARNING') as logs:
            with scope:
                pass
        self.assertIn('restore failed', '\n'.join(logs.output))
        spark.sql.assert_called_with('DROP DATABASE `{}` CASCADE'.format(scope.database_name))


if __name__ == '__main__':
    unittest.main()
