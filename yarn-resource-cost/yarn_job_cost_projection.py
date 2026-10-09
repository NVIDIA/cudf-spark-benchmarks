#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Project annual costs from complete YARN reports and explicit planning inputs."""

from __future__ import annotations

import argparse
import copy
import json
import math
from decimal import Decimal, InvalidOperation
from pathlib import Path


ZERO = Decimal(0)


def _object(value: object, label: str, required: set, optional: set) -> dict:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    missing = required - value.keys()
    extra = value.keys() - required - optional
    if missing or extra:
        raise ValueError(
            f"{label}: missing fields {sorted(missing)}; unknown fields {sorted(extra)}"
        )
    return value


def _list(value: object, label: str) -> list:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be a list")
    return value


def _text(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be a nonempty string")
    return value


def _number(value: object, label: str, signed: bool = False) -> Decimal:
    try:
        number = Decimal(str(value))
    except (InvalidOperation, ValueError):
        raise ValueError(f"{label} must be a finite number") from None
    if not number.is_finite() or (not signed and number < 0):
        raise ValueError(f"{label} must be finite" + ("" if signed else " and nonnegative"))
    if abs(number) > Decimal("1e18"):
        raise ValueError(f"{label} is too large (maximum absolute value: 1e18)")
    return number


def _integer(value: object, label: str, lower: int, upper: int) -> int:
    if type(value) is not int or not lower <= value <= upper:
        raise ValueError(f"{label} must be an integer from {lower} to {upper}")
    return value


def _json_numbers(value: object) -> object:
    if isinstance(value, Decimal):
        result = round(float(value), 8)
        if not math.isfinite(result):
            raise ValueError("Projection exceeds the supported numeric range")
        return result
    if isinstance(value, dict):
        return {key: _json_numbers(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_json_numbers(item) for item in value]
    return value


def _applications(report: dict, label: str) -> dict[str, dict]:
    if not isinstance(report, dict) or type(report.get("schema_version")) is not int:
        raise ValueError(f"{label} must be a schema_version 1 single-run report")
    if report["schema_version"] != 1 or "applications" not in report:
        raise ValueError(f"{label} must be a schema_version 1 single-run report")
    index = {}
    for app in _list(report["applications"], f"{label}.applications"):
        if not isinstance(app, dict):
            raise ValueError(f"{label}.applications entries must be objects")
        app_id = _text(app.get("application_id"), f"{label}.application_id")
        if app_id in index:
            raise ValueError(f"{label}: duplicate application_id {app_id}")
        index[app_id] = app
    return index


def _usage(app: dict, app_id: str) -> dict[str, Decimal]:
    if app.get("complete") is not True:
        raise ValueError(f"{app_id}: incomplete accounting cannot be projected")
    if app.get("final_status") != "SUCCEEDED":
        raise ValueError(f"{app_id}: projection requires final_status SUCCEEDED")
    vector = app.get("node_equivalent_seconds_by_instance_type")
    if not isinstance(vector, dict) or not vector:
        raise ValueError(f"{app_id}: missing node-class resource accounting")
    return {
        _text(node_class, "node class"): _number(seconds, f"{app_id}.{node_class}")
        for node_class, seconds in vector.items()
    }


def _scenario(
    settings: dict, label: str, basis: str, currency: str, years: int,
    workloads: list[dict], apps: dict[str, dict],
) -> dict:
    _object(settings, label, set(), {"worker_pools", "annual_costs", "cash_events"})
    annual_usage: dict[str, Decimal] = {}
    attributed_cost = ZERO
    selections = []
    selected_ids = set()
    for workload in workloads:
        app_id = workload[f"{label}_application_id"]
        if app_id in selected_ids:
            raise ValueError(f"{label}: application {app_id} selected more than once")
        selected_ids.add(app_id)
        if app_id not in apps:
            raise ValueError(f"{label}: application {app_id} not found")
        app = apps[app_id]
        vector = _usage(app, app_id)
        runs = _number(workload["annual_runs"], "annual_runs")
        for node_class, seconds in vector.items():
            annual_usage[node_class] = (
                annual_usage.get(node_class, ZERO) + seconds * runs / 3600
            )
        if basis == "allocated":
            if app.get("worker_cost_currency") != currency:
                raise ValueError(f"{app_id}: worker_cost_currency must be {currency}")
            attributed_cost += _number(app.get("worker_cost"), f"{app_id}.worker_cost") * runs
        selections.append({
            "workload": workload["name"],
            "annual_runs": runs,
            "application": copy.deepcopy(app),
        })

    pools = _list(settings.get("worker_pools", []), f"{label}.worker_pools")
    if basis == "allocated" and pools:
        raise ValueError("worker_pools require cost_basis provisioned to avoid double counting")
    capacity: dict[str, Decimal] = {}
    worker_cost = ZERO if basis == "provisioned" else attributed_cost
    for pool in pools:
        _object(pool, "worker pool", {
            "node_class", "node_count", "uptime_hours_per_year", "hourly_rate", "rate_source",
        }, set())
        node_class = _text(pool["node_class"], "node_class")
        count = _integer(pool["node_count"], "node_count", 1, 1000000)
        hours = _number(pool["uptime_hours_per_year"], "uptime_hours_per_year")
        if hours > 8784:
            raise ValueError("uptime_hours_per_year cannot exceed 8784")
        rate = _number(pool["hourly_rate"], "hourly_rate")
        _text(pool["rate_source"], "rate_source")
        capacity[node_class] = capacity.get(node_class, ZERO) + count * hours
        worker_cost += count * hours * rate
    if basis == "provisioned":
        if not pools:
            raise ValueError(f"{label}: provisioned costs require worker_pools")
        for node_class, hours in annual_usage.items():
            if node_class not in capacity or hours > capacity[node_class]:
                raise ValueError(
                    f"{label}: annual allocation for {node_class} exceeds provisioned capacity"
                )

    annual_additional = ZERO
    for item in _list(settings.get("annual_costs", []), f"{label}.annual_costs"):
        _object(item, "annual cost", {"name", "amount"}, set())
        _text(item["name"], "annual cost name")
        annual_additional += _number(item["amount"], "annual cost amount")
    events = [ZERO] * (years + 1)
    for item in _list(settings.get("cash_events", []), f"{label}.cash_events"):
        _object(item, "cash event", {"name", "year", "amount"}, set())
        _text(item["name"], "cash event name")
        year = _integer(item["year"], "cash event year", 0, years)
        events[year] += _number(item["amount"], "cash event amount", signed=True)
    annual = worker_cost + annual_additional
    outflows = [events[0]] + [annual + event for event in events[1:]]
    return {
        "annual_worker_cost": worker_cost,
        "annual_additional_cost": annual_additional,
        "annual_cost": annual,
        "cash_events_by_year": events,
        "outflows_by_year": outflows,
        "horizon_cost": sum(outflows, ZERO),
        "annual_allocated_node_hours_by_class": annual_usage,
        "annual_provisioned_node_hours_by_class": capacity,
        "selected_workloads": selections,
    }


def _compare(baseline: dict, candidate: dict, years: int, discount: Decimal) -> dict:
    annual_savings = baseline["annual_cost"] - candidate["annual_cost"]
    net_flows = [
        before - after for before, after in zip(
            baseline["outflows_by_year"], candidate["outflows_by_year"]
        )
    ]
    event_deltas = [
        before - after for before, after in zip(
            baseline["cash_events_by_year"], candidate["cash_events_by_year"]
        )
    ]
    investment = sum((max(ZERO, -delta) for delta in event_deltas), ZERO)
    net_savings = sum(net_flows, ZERO)
    # Recurring savings accrue uniformly; one-time events occur at year boundaries.
    # Require the balance to stay nonnegative through later replacements as well.
    balances = [event_deltas[0]]
    events_to_date = event_deltas[0]
    for month in range(1, years * 12 + 1):
        if month % 12 == 0:
            events_to_date += event_deltas[month // 12]
        balances.append(events_to_date + annual_savings * month / 12)
    minimum = balances[-1]
    payback = None
    if investment:
        for month in range(len(balances) - 1, -1, -1):
            minimum = min(minimum, balances[month])
            if minimum >= 0:
                payback = month
    return {
        "annual_savings": annual_savings,
        "horizon_net_savings": net_savings,
        "incremental_investment": investment,
        "roi_percent": net_savings / investment * 100 if investment else None,
        "npv": sum((
            flow / (1 + discount / 100) ** year
            for year, flow in enumerate(net_flows)
        ), ZERO),
        "sustained_payback_months": payback,
        "net_flows_by_year": net_flows,
    }


def project_costs(baseline_report: dict, candidate_report: dict, plan: dict) -> dict:
    """Return an offline projection; reject missing or incomparable cost evidence.

    Inputs are single-run ``yarn-resource-cost --output-json`` reports. The plan
    explicitly pairs application IDs and provides annual frequency and costs.
    Neither input reports nor the plan are modified. No prices are looked up.
    """
    _object(plan, "plan", {
        "schema_version", "cost_basis", "currency", "years", "workloads",
        "baseline", "candidate",
    }, {"discount_rate_percent"})
    _integer(plan["schema_version"], "schema_version", 1, 1)
    years = _integer(plan["years"], "years", 1, 50)
    currency = _text(plan["currency"], "currency")
    basis = plan["cost_basis"]
    if basis not in ("allocated", "provisioned"):
        raise ValueError("cost_basis must be allocated or provisioned")
    discount = _number(plan.get("discount_rate_percent", 0), "discount_rate_percent")
    workloads = _list(plan["workloads"], "workloads")
    if not workloads:
        raise ValueError("workloads must not be empty")
    names = set()
    for workload in workloads:
        _object(workload, "workload", {
            "name", "annual_runs", "baseline_application_id", "candidate_application_id",
        }, set())
        name = _text(workload["name"], "workload name")
        if name in names:
            raise ValueError(f"duplicate workload name {name}")
        names.add(name)
        for side in ("baseline", "candidate"):
            _text(workload[f"{side}_application_id"], f"{side}_application_id")
        if _number(workload["annual_runs"], "annual_runs") == 0:
            raise ValueError("annual_runs must be positive")
    reports = {"baseline": baseline_report, "candidate": candidate_report}
    scenarios = {
        side: _scenario(
            plan[side], side, basis, currency, years, workloads,
            _applications(report, f"{side}_report"),
        ) for side, report in reports.items()
    }
    return _json_numbers({
        "schema_version": 1,
        "currency": currency,
        "cost_basis": basis,
        "plan": copy.deepcopy(plan),
        "source_pricing": {
            side: copy.deepcopy(report.get("pricing", {}))
            for side, report in reports.items()
        },
        **scenarios,
        "comparison": _compare(scenarios["baseline"], scenarios["candidate"], years, discount),
        "assumptions": [
            "Workload equivalence is supplied by the caller, not verified from application IDs.",
            "Frequencies, prices and recurring costs stay constant over the horizon.",
            "Recurring savings accrue uniformly for payback; NPV discounts them at year end.",
            "Cash events occur at year boundaries; year 0 is before the first run.",
            "Only explicitly listed costs are included; taxes and financing are not inferred.",
            "Allocated costs are task attribution, not a whole-cluster cash bill."
            if basis == "allocated" else
            "Provisioned costs include paid idle capacity; "
            "capacity checks do not prove scheduling feasibility.",
        ],
    })


def projection_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="yarn-resource-cost project", description=__doc__
    )
    parser.add_argument("--baseline-report", type=Path, required=True)
    parser.add_argument("--candidate-report", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--output-json", type=Path)
    args = parser.parse_args(argv)
    try:
        inputs = [
            json.loads(path.read_text(encoding="utf-8"))
            for path in (args.baseline_report, args.candidate_report, args.plan)
        ]
        result = project_costs(*inputs)
        rendered = json.dumps(result, indent=2, sort_keys=True, allow_nan=False) + "\n"
        if args.output_json:
            args.output_json.parent.mkdir(parents=True, exist_ok=True)
            args.output_json.write_text(rendered, encoding="utf-8")
        else:
            print(rendered, end="")
    except (OSError, UnicodeError) as error:
        raise ValueError(f"Cannot read or write projection files: {error}") from error
    return 0
