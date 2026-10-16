# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Tests for run-scoped managed Delta shallow clones."""

import unittest
from unittest.mock import Mock, call, patch

from delta_clone import DeltaCloneScope


class DeltaCloneScopeTest(unittest.TestCase):
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


if __name__ == '__main__':
    unittest.main()
