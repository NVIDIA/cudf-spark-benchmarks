#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yarn_job_cost_adapters as adapters
import yarn_job_cost_core as core


ROOT = Path(__file__).resolve().parent
FIXTURE = ROOT / "tests" / "fixtures" / "on_prem"
SCRIPT = ROOT / "yarn_resource_cost.py"


class ProviderNeutralAccountingTest(unittest.TestCase):
    def container(self, **updates) -> core.Container:
        values = {
            "container_id": "container_1_0001_01_000002",
            "application_id": "application_1_0001",
            "node_id": "worker1",
            "start_ms": 0,
            "finish_ms": 1000,
            "memory_mb": 2048,
            "node_memory_mb": 8192,
            "vcores": 2,
            "node_vcores": 8,
            "resources": {"memory-mb": 2048, "vcores": 2},
            "node_resources": {"memory-mb": 8192, "vcores": 8},
        }
        values.update(updates)
        return core.Container(**values)

    def test_default_calculator_uses_memory_only(self):
        container = self.container(
            vcores=8,
            resources={"memory-mb": 2048, "vcores": 8, "yarn.io/gpu": 1},
            node_resources={"memory-mb": 8192, "vcores": 8, "yarn.io/gpu": 1},
        )
        self.assertEqual(0.25, core.container_node_share(container, "default"))

    def test_dominant_calculator_uses_arbitrary_custom_resource(self):
        container = self.container(
            resources={"memory-mb": 2048, "vcores": 2, "vendor/device": 3},
            node_resources={"memory-mb": 8192, "vcores": 8, "vendor/device": 4},
        )
        self.assertEqual(0.75, core.container_node_share(container, "dominant"))

    def test_dominant_rejects_missing_allocated_resource_capacity(self):
        container = self.container(
            resources={"memory-mb": 2048, "vcores": 2, "yarn.io/gpu": 1}
        )
        with self.assertRaisesRegex(ValueError, "yarn.io/gpu"):
            core.container_node_share(container, "dominant")

    def test_fair_scheduler_drf_policy_is_detected_from_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "hadoop-yarn-resourcemanager.log"
            path.write_text(
                "2026-01-01 00:00:00,000 INFO FairScheduler: "
                "policy=DominantResourceFairnessPolicy\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(path)
        self.assertEqual("DominantResourceCalculator", evidence.calculator_class)
        self.assertEqual("DominantResourceFairnessPolicy", evidence.scheduler_policy)

    def test_nodemanager_registration_preserves_reported_worker_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            log_dir = Path(directory) / "hadoop-yarn"
            log_dir.mkdir()
            path = log_dir / "hadoop-yarn-nodemanager.log"
            path.write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker1:8041 with total resource of "
                "<memory:8192, vCores:8, yarn.io/gpu:1>\n"
                "2026-01-01 00:00:01,000 INFO X: Start request for "
                "container_1_0001_01_000002 with resource "
                "<memory:2048, vCores:2, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(log_dir)

        node = evidence.nodes["worker1"]
        container = evidence.containers["container_1_0001_01_000002"]
        self.assertEqual(8192, node.memory_mb)
        self.assertEqual(1, node.resources["yarn.io/gpu"])
        self.assertEqual("worker1", container.node_id)
        self.assertEqual(8192, container.node_memory_mb)

    def test_nodemanager_identity_is_preserved_across_split_log_files(self):
        with tempfile.TemporaryDirectory() as directory:
            log_dir = Path(directory) / "hadoop-yarn"
            log_dir.mkdir()
            (log_dir / "00-start.log").write_text(
                "2026-01-01 00:00:01,000 INFO X: Start request for "
                "container_1_0001_01_000002 with resource "
                "<memory:2048, vCores:2, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            (log_dir / "01-registration.log").write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker1:8041 with total resource of "
                "<memory:8192, vCores:8, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(log_dir)

        container = evidence.containers["container_1_0001_01_000002"]
        self.assertEqual("worker1", container.node_id)
        self.assertEqual(8192, container.node_memory_mb)
        self.assertEqual(8, container.node_vcores)
        self.assertEqual(1, container.node_gpus)

    def test_nodemanager_identity_does_not_cross_workers_in_same_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            log_dir = Path(directory) / "hadoop-yarn"
            log_dir.mkdir()
            (log_dir / "00-worker-a.log").write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker-a:8041 with total resource of "
                "<memory:8192, vCores:8, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            (log_dir / "01-worker-b.log").write_text(
                "2026-01-01 00:00:01,000 INFO X: Start request for "
                "container_1_0001_01_000002 with resource "
                "<memory:2048, vCores:2, yarn.io/gpu:1>\n"
                "2026-01-01 00:00:02,000 INFO X: Registered with ResourceManager "
                "as worker-b:8041 with total resource of "
                "<memory:16384, vCores:16, yarn.io/gpu:2>\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(log_dir)

        container = evidence.containers["container_1_0001_01_000002"]
        self.assertEqual("worker-b", container.node_id)
        self.assertEqual(16384, container.node_memory_mb)
        self.assertEqual(16, container.node_vcores)
        self.assertEqual(2, container.node_gpus)

    def test_ambiguous_split_nodemanager_logs_do_not_guess_worker_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            log_dir = Path(directory) / "hadoop-yarn"
            log_dir.mkdir()
            (log_dir / "00-worker-a.log").write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker-a:8041 with total resource of "
                "<memory:8192, vCores:8, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            (log_dir / "01-worker-b.log").write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker-b:8041 with total resource of "
                "<memory:16384, vCores:16, yarn.io/gpu:2>\n",
                encoding="utf-8",
            )
            (log_dir / "02-start.log").write_text(
                "2026-01-01 00:00:01,000 INFO X: Start request for "
                "container_1_0001_01_000002 with resource "
                "<memory:2048, vCores:2, yarn.io/gpu:1>\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(log_dir)

        container = evidence.containers["container_1_0001_01_000002"]
        self.assertEqual("hadoop-yarn", container.node_id)
        self.assertEqual(0, container.node_memory_mb)
        self.assertEqual(0, container.node_vcores)
        self.assertEqual(0, container.node_gpus)

    def test_resourcemanager_assignment_preserves_host_without_registration(self):
        with tempfile.TemporaryDirectory() as directory:
            log_dir = Path(directory) / "hadoop-yarn"
            log_dir.mkdir()
            path = log_dir / "hadoop-yarn-resourcemanager.log"
            path.write_text(
                "2026-01-01 00:00:01,000 INFO X: Assigned container "
                "container_1_0001_01_000002 of capacity "
                "<memory:2048, vCores:2, yarn.io/gpu:1> "
                "on host worker1:8041\n",
                encoding="utf-8",
            )
            evidence = core.parse_yarn_logs(log_dir)

        node = evidence.nodes["worker1"]
        container = evidence.containers["container_1_0001_01_000002"]
        self.assertIsNone(node.memory_mb)
        self.assertIsNone(node.vcores)
        self.assertEqual({}, node.resources)
        self.assertEqual("worker1", container.node_id)
        self.assertEqual(0, container.node_memory_mb)
        self.assertEqual(0, container.node_vcores)


class AdapterTest(unittest.TestCase):
    def test_catalog_cost_and_node_mapping(self):
        evidence = core.parse_yarn_logs(FIXTURE / "yarn")
        adapters.apply_node_class_map(evidence, FIXTURE / "node-classes.json")
        self.assertEqual("onprem:worker-8", evidence.nodes["worker1"].node_class)
        catalog = adapters.load_price_catalog(FIXTURE / "prices.json")
        applications = [
            {
                "complete": True,
                "node_equivalent_seconds_by_instance_type": {
                    "onprem:worker-8": 10.0
                },
                "warnings": [],
            }
        ]
        adapters.apply_catalog_costs(applications, catalog)
        self.assertEqual(0.01, applications[0]["worker_cost"])

    def test_missing_catalog_rate_suppresses_final_cost(self):
        catalog = adapters.load_price_catalog(FIXTURE / "prices.json")
        applications = [
            {
                "complete": True,
                "node_equivalent_seconds_by_instance_type": {"unknown": 1.0},
                "warnings": [],
            }
        ]
        adapters.apply_catalog_costs(applications, catalog)
        self.assertFalse(applications[0]["complete"])
        self.assertEqual("", applications[0]["worker_cost"])


class PortableCliTest(unittest.TestCase):
    def test_reported_nodes_ignore_daemon_log_directories(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rm_log = (FIXTURE / "yarn" / "hadoop-yarn-resourcemanager-rm.log").read_text(
                encoding="utf-8"
            ).replace(
                "registered with capability: <memory:8192, vCores:8>",
                "registered with capability: <memory:8192, vCores:8, "
                "yarn.io/gpu:1> instanceType(STRING)=g4dn.4xlarge",
            )
            rm_log += (
                "2026-01-01 00:00:00,200 INFO RMNodeImpl: NodeManager from node "
                "worker2(cmPort: 8041 httpPort: 8042) registered with capability: "
                "<memory:8192, vCores:8, yarn.io/gpu:1> "
                "instanceType(STRING)=g4dn.4xlarge\n"
            )
            full_logs = root / "full" / "hadoop-yarn"
            filtered_logs = root / "filtered" / "ip-master"
            for log_dir in (full_logs, filtered_logs):
                log_dir.mkdir(parents=True)
                (log_dir / "hadoop-yarn-resourcemanager.log").write_text(
                    rm_log, encoding="utf-8"
                )
            (full_logs / "hadoop-yarn-nodemanager.log").write_text(
                "2026-01-01 00:00:00,000 INFO X: Registered with ResourceManager "
                "as worker1:8041 with total resource of "
                "<memory:8192, vCores:8, yarn.io/gpu:1> "
                "instanceType(STRING)=g4dn.4xlarge\n",
                encoding="utf-8",
            )

            outputs = []
            for log_dir in (full_logs, filtered_logs):
                output = root / f"{log_dir.parent.name}.json"
                completed = subprocess.run(
                    [
                        sys.executable,
                        "-S",
                        str(SCRIPT),
                        "--adapter",
                        "on-prem",
                        "--event-log-root",
                        str(FIXTURE),
                        "--yarn-log-root",
                        str(log_dir),
                        "--node-class-map",
                        str(FIXTURE / "node-classes.json"),
                        "--output-json",
                        str(output),
                    ],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(0, completed.returncode, completed.stderr)
                outputs.append(json.loads(output.read_text(encoding="utf-8")))

        self.assertEqual(outputs[0]["applications"], outputs[1]["applications"])
        self.assertEqual(outputs[0]["summary"], outputs[1]["summary"])
        self.assertTrue(outputs[0]["applications"][0]["complete"])
        for output in outputs:
            self.assertEqual({"worker1", "worker2"}, set(output["nodes"]))
            self.assertEqual(1, output["nodes"]["worker1"]["resources"]["yarn.io/gpu"])
            self.assertEqual(1, output["nodes"]["worker2"]["resources"]["yarn.io/gpu"])

    def test_entry_point_formats_expected_errors(self):
        completed = subprocess.run(
            [
                sys.executable,
                "-c",
                "import yarn_resource_cost; yarn_resource_cost.cli_main()",
                "--adapter",
                "on-prem",
                "--event-log-root",
                "/definitely/not/a/yarn/event/log",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(2, completed.returncode)
        self.assertTrue(completed.stderr.startswith("error: "), completed.stderr)
        self.assertNotIn("Traceback", completed.stderr)

    def test_on_prem_fixture_end_to_end_with_catalog(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.json"
            completed = subprocess.run(
                [
                    sys.executable,
                    "-S",
                    str(SCRIPT),
                    "--adapter",
                    "on-prem",
                    "--event-log-root",
                    str(FIXTURE),
                    "--yarn-log-root",
                    str(FIXTURE / "yarn"),
                    "--node-class-map",
                    str(FIXTURE / "node-classes.json"),
                    "--pricing",
                    "catalog",
                    "--price-catalog",
                    str(FIXTURE / "prices.json"),
                    "--output-json",
                    str(output),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, completed.returncode, completed.stderr)
            payload = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(1, payload["schema_version"])
        self.assertEqual("on-prem", payload["adapter"])
        application = payload["applications"][0]
        self.assertTrue(application["complete"])
        self.assertEqual(2.0, application["node_equivalent_seconds"])
        self.assertEqual(0.002, application["worker_cost"])
        self.assertEqual("USD", application["worker_cost_currency"])


if __name__ == "__main__":
    unittest.main()
