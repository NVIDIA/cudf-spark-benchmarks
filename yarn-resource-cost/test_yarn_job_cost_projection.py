#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Synthetic accounting examples, independently checkable in currency and hours."""

import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from yarn_resource_cost import project_costs


ROOT = Path(__file__).resolve().parent
SCRIPT = ROOT / "yarn_resource_cost.py"
FIXTURE = ROOT / "tests" / "fixtures" / "on_prem"


def report(app_id, node_class, seconds, cost):
    return {
        "schema_version": 1,
        "pricing": {"mode": "catalog", "source": "synthetic test prices"},
        "applications": [{
            "application_id": app_id,
            "complete": True,
            "final_status": "SUCCEEDED",
            "node_equivalent_seconds_by_instance_type": {node_class: seconds},
            "resource_calculator": "default",
            "worker_cost": cost,
            "worker_cost_currency": "USD",
            "warnings": [],
        }],
    }


def pool(node_class, rate, count=1, hours=8760):
    return {
        "node_class": node_class, "hourly_rate": rate, "node_count": count,
        "uptime_hours_per_year": hours, "rate_source": "synthetic planning rate",
    }


class ProjectionTest(unittest.TestCase):
    def setUp(self):
        self.cpu = report("cpu-run", "cpu", 3600, 10)
        self.gpu = report("gpu-run", "gpu", 900, 5)
        self.plan = {
            "schema_version": 1, "currency": "USD", "years": 3,
            "cost_basis": "allocated",
            "workloads": [{
                "name": "etl", "annual_runs": 100,
                "baseline_application_id": "cpu-run",
                "candidate_application_id": "gpu-run",
            }],
            "baseline": {},
            "candidate": {"cash_events": [{
                "year": 0, "name": "migration", "amount": 1000,
            }]},
        }

    def evaluate(self):
        return project_costs(self.cpu, self.gpu, self.plan)

    def provisioned(self):
        self.plan["cost_basis"] = "provisioned"
        self.plan["baseline"] = {"worker_pools": [pool("cpu", 10)]}
        self.plan["candidate"] = {"worker_pools": [pool("gpu", 20)]}

    def test_allocated_cost_and_migration_payback(self):
        result = self.evaluate()
        # 100 * $10/year vs 100 * $5/year, plus a $1000 initial migration.
        self.assertEqual(1000, result["baseline"]["annual_cost"])
        self.assertEqual(500, result["candidate"]["annual_cost"])
        self.assertEqual(3000, result["baseline"]["horizon_cost"])
        self.assertEqual(2500, result["candidate"]["horizon_cost"])
        comparison = result["comparison"]
        self.assertEqual(500, comparison["horizon_net_savings"])
        self.assertEqual(50, comparison["roi_percent"])
        self.assertEqual(24, comparison["sustained_payback_months"])
        self.assertEqual([-1000, 500, 500, 500], comparison["net_flows_by_year"])

    def test_discounted_cash_flow(self):
        self.plan["discount_rate_percent"] = 10
        # -1000 + 500/1.1 + 500/1.21 + 500/1.331.
        self.assertAlmostEqual(243.42599549, self.evaluate()["comparison"]["npv"])

    def test_later_replacement_prevents_premature_payback(self):
        self.plan["candidate"]["cash_events"] = [
            {"year": 0, "name": "migration", "amount": 100},
            {"year": 2, "name": "replacement", "amount": 1200},
        ]
        result = self.evaluate()["comparison"]
        # Balance first turns positive in month 3, negative again at month 24,
        # and stays nonnegative only from month 32 ($1300 / $500 * 12).
        self.assertEqual(32, result["sustained_payback_months"])
        self.assertEqual(1300, result["incremental_investment"])

    def test_no_payback_within_horizon(self):
        self.plan["candidate"]["cash_events"][0]["amount"] = 2000
        result = self.evaluate()["comparison"]
        self.assertIsNone(result["sustained_payback_months"])
        self.assertEqual(-25, result["roi_percent"])

    def test_no_investment_does_not_invent_roi(self):
        self.plan["candidate"] = {}
        result = self.evaluate()["comparison"]
        self.assertEqual(1500, result["horizon_net_savings"])
        self.assertIsNone(result["roi_percent"])
        self.assertIsNone(result["sustained_payback_months"])

    def test_full_year_bill_can_reverse_per_job_savings(self):
        self.provisioned()
        result = self.evaluate()
        self.assertEqual(87600, result["baseline"]["annual_worker_cost"])
        self.assertEqual(175200, result["candidate"]["annual_worker_cost"])
        self.assertEqual(-87600, result["comparison"]["annual_savings"])

    def test_shared_fleet_is_not_billed_again_per_workload(self):
        self.provisioned()
        cpu2 = copy.deepcopy(self.cpu["applications"][0])
        gpu2 = copy.deepcopy(self.gpu["applications"][0])
        cpu2["application_id"], gpu2["application_id"] = "cpu-2", "gpu-2"
        self.cpu["applications"].append(cpu2)
        self.gpu["applications"].append(gpu2)
        self.plan["workloads"].append({
            "name": "second-job", "annual_runs": 200,
            "baseline_application_id": "cpu-2", "candidate_application_id": "gpu-2",
        })
        result = self.evaluate()
        self.assertEqual(87600, result["baseline"]["annual_worker_cost"])
        self.assertEqual({"cpu": 300}, result["baseline"]["annual_allocated_node_hours_by_class"])

    def test_retained_idle_cpu_fleet_is_paid_for(self):
        self.provisioned()
        self.plan["candidate"]["worker_pools"].append(pool("retained-cpu", 10))
        result = self.evaluate()["candidate"]
        self.assertEqual(262800, result["annual_worker_cost"])
        self.assertEqual(8760, result["annual_provisioned_node_hours_by_class"]["retained-cpu"])

    def test_heterogeneous_capacity_is_not_combined_across_classes(self):
        self.provisioned()
        self.cpu["applications"][0]["node_equivalent_seconds_by_instance_type"] = {
            "small": 1800, "large": 900,
        }
        self.plan["baseline"]["worker_pools"] = [
            pool("small", 2, count=2, hours=100), pool("large", 4, hours=100),
        ]
        result = self.evaluate()["baseline"]
        self.assertEqual(800, result["annual_worker_cost"])
        self.assertEqual(
            {"small": 50, "large": 25}, result["annual_allocated_node_hours_by_class"]
        )
        self.plan["baseline"]["worker_pools"][1]["uptime_hours_per_year"] = 24
        with self.assertRaisesRegex(ValueError, "large exceeds provisioned capacity"):
            self.evaluate()

    def test_owned_hardware_uses_explicit_purchase_and_operating_costs(self):
        self.provisioned()
        self.plan["candidate"] = {
            "worker_pools": [pool("gpu", 0)],
            "annual_costs": [
                {"name": "electricity", "amount": 1200},
                {"name": "maintenance", "amount": 300},
            ],
            "cash_events": [
                {"year": 0, "name": "purchase", "amount": 10000},
                {"year": 3, "name": "resale", "amount": -2000},
            ],
        }
        result = self.evaluate()["candidate"]
        self.assertEqual(0, result["annual_worker_cost"])
        self.assertEqual(1500, result["annual_cost"])
        self.assertEqual(12500, result["horizon_cost"])

    def test_unpriced_reports_are_usable_only_with_explicit_provisioned_rates(self):
        for report_data in (self.cpu, self.gpu):
            report_data["applications"][0]["worker_cost"] = ""
            report_data["applications"][0]["worker_cost_currency"] = ""
        with self.assertRaisesRegex(ValueError, "worker_cost_currency"):
            self.evaluate()
        self.provisioned()
        self.assertEqual(-87600, self.evaluate()["comparison"]["annual_savings"])

    def test_incomplete_failed_missing_price_and_mixed_currency_are_rejected(self):
        cases = [
            ({"complete": False}, "incomplete"),
            ({"complete": "true"}, "incomplete"),
            ({"final_status": "FAILED"}, "SUCCEEDED"),
            ({"worker_cost": ""}, "finite number"),
            ({"worker_cost": -1}, "nonnegative"),
            ({"worker_cost_currency": "EUR"}, "worker_cost_currency"),
            ({"node_equivalent_seconds_by_instance_type": {}}, "node-class"),
        ]
        for updates, message in cases:
            with self.subTest(updates=updates):
                broken = copy.deepcopy(self.gpu)
                broken["applications"][0].update(updates)
                with self.assertRaisesRegex(ValueError, message):
                    project_costs(self.cpu, broken, self.plan)

    def test_incomplete_report_also_blocks_provisioned_comparison(self):
        self.provisioned()
        self.cpu["applications"][0]["complete"] = False
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.evaluate()

    def test_no_implicit_matching_or_duplicate_counting(self):
        self.plan["workloads"][0]["candidate_application_id"] = "missing-run"
        with self.assertRaisesRegex(ValueError, "not found"):
            self.evaluate()
        self.plan["workloads"][0]["candidate_application_id"] = "gpu-run"
        second = {**self.plan["workloads"][0], "name": "same-run-again"}
        self.plan["workloads"].append(second)
        with self.assertRaisesRegex(ValueError, "selected more than once"):
            self.evaluate()

    def test_duplicate_report_ids_and_comparison_reports_are_rejected(self):
        self.cpu["applications"].append(copy.deepcopy(self.cpu["applications"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate application_id"):
            self.evaluate()
        with self.assertRaisesRegex(ValueError, "single-run report"):
            project_costs({"schema_version": 1, "baseline": self.cpu}, self.gpu, self.plan)

    def test_bad_plans_fail_instead_of_silently_dropping_costs(self):
        cases = [
            ({"schema_version": True}, "schema_version"),
            ({"years": 1.5}, "years"),
            ({"years": 0}, "years"),
            ({"years": 51}, "years"),
            ({"discount_rate_percent": -1}, "nonnegative"),
            ({"cost_basis": "mixed"}, "cost_basis"),
            ({"workloads": []}, "must not be empty"),
            ({"upfront_cost": 1000}, "unknown fields"),
            ({"candidate": {"annual_cost": 100}}, "unknown fields"),
            ({"candidate": {"worker_pools": [pool("gpu", 20)]}}, "double counting"),
        ]
        for updates, message in cases:
            with self.subTest(updates=updates):
                with self.assertRaisesRegex(ValueError, message):
                    project_costs(self.cpu, self.gpu, {**self.plan, **updates})

    def test_invalid_frequencies_and_nonfinite_values_are_rejected(self):
        for value in (0, -1, True, float("nan"), float("inf"), "1e999", "wrong"):
            with self.subTest(value=value):
                self.plan["workloads"][0]["annual_runs"] = value
                with self.assertRaises(ValueError):
                    self.evaluate()

    def test_cash_event_must_be_within_the_horizon(self):
        self.plan["candidate"]["cash_events"][0]["year"] = 4
        with self.assertRaisesRegex(ValueError, "cash event year"):
            self.evaluate()

    def test_inputs_and_provenance_are_preserved(self):
        before = copy.deepcopy((self.cpu, self.gpu, self.plan))
        result = self.evaluate()
        self.assertEqual(before, (self.cpu, self.gpu, self.plan))
        self.assertEqual(self.cpu["pricing"], result["source_pricing"]["baseline"])
        self.assertEqual(self.plan, result["plan"])
        result["baseline"]["selected_workloads"][0]["application"]["warnings"].append("changed")
        self.assertEqual([], self.cpu["applications"][0]["warnings"])

    def test_cli_projects_real_accounting_fixture_offline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "cost.json"
            collected = subprocess.run([
                sys.executable, "-S", str(SCRIPT), "--adapter", "on-prem",
                "--event-log-root", str(FIXTURE), "--yarn-log-root", str(FIXTURE / "yarn"),
                "--node-class-map", str(FIXTURE / "node-classes.json"),
                "--pricing", "catalog", "--price-catalog", str(FIXTURE / "prices.json"),
                "--output-json", str(source),
            ], capture_output=True, text=True)
            self.assertEqual(0, collected.returncode, collected.stderr)
            workload = self.plan["workloads"][0]
            workload["baseline_application_id"] = "application_1_0001"
            workload["candidate_application_id"] = "application_1_0001"
            plan_path = root / "plan.json"
            plan_path.write_text(json.dumps(self.plan), encoding="utf-8")
            output = root / "out" / "projection.json"
            command = [
                sys.executable, "-S", str(SCRIPT), "project",
                "--baseline-report", str(source), "--candidate-report", str(source),
                "--plan", str(plan_path), "--output-json", str(output),
            ]
            completed = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(0, completed.returncode, completed.stderr)
            result = json.loads(output.read_text(encoding="utf-8"))
            # The existing fixture costs $0.002/run; 100 runs cost $0.20/year.
            self.assertEqual(0.2, result["baseline"]["annual_worker_cost"])
            self.assertEqual(-1000, result["comparison"]["horizon_net_savings"])

    def test_cli_input_errors_have_no_traceback(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "input.json"
            for contents in (None, "not-json", "null", '{"schema_version": 1}'):
                with self.subTest(contents=contents):
                    if contents is not None:
                        source.write_text(contents, encoding="utf-8")
                    completed = subprocess.run([
                        sys.executable, str(SCRIPT), "project",
                        "--baseline-report", str(source), "--candidate-report", str(source),
                        "--plan", str(source),
                    ], capture_output=True, text=True)
                    self.assertEqual(2, completed.returncode, completed.stderr)
                    self.assertTrue(completed.stderr.startswith("error: "))
                    self.assertNotIn("Traceback", completed.stderr)


if __name__ == "__main__":
    unittest.main()
