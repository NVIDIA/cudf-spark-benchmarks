# Annual cost and payback projection

`yarn-resource-cost project` extends existing resource accounting with an
offline planning calculation. It reads two **single-run** JSON reports produced
by `yarn-resource-cost --output-json`, pairs explicitly selected applications,
and adds annual frequency, operating costs and one-time cash events. It does
not parse logs again, predict GPU speedup, or look up prices.

First collect one baseline report and one candidate report using the existing
CLI. The candidate can be a GPU cluster or any alternative configuration. Then:

```bash
yarn-resource-cost project \
  --baseline-report cpu-cost.json \
  --candidate-report gpu-cost.json \
  --plan annual-plan.json \
  --output-json projection.json
```

For the source bundle, replace `yarn-resource-cost` with
`python3 yarn_resource_cost.py`. Omit `--output-json` to print JSON to stdout.
The Python API is `from yarn_resource_cost import project_costs`, followed by
`project_costs(baseline_report, candidate_report, plan)` with decoded JSON
objects. Input dictionaries are not modified.

## Choose the cost basis

Both scenarios must use the same basis, selected once in the plan:

| `cost_basis` | Annual worker cost | What it means |
| --- | --- | --- |
| `allocated` | Sum of existing `worker_cost * annual_runs` for selected applications | Projected task-attributed cost; **not** the whole-cluster bill |
| `provisioned` | Sum of `node_count * uptime_hours_per_year * hourly_rate` for all listed pools | Planned full worker bill, including paid idle capacity |

Allocated mode requires complete, successfully finished and priced applications
in the plan's currency. A low task-attributed cost does not establish that a
GPU migration reduces the cash bill. For example, $10 CPU and $5 GPU per run
give $1,000 and $500 of annual allocated costs at 100 runs/year. Keeping one
$10/hour CPU node and one $20/hour GPU node on for 8,760 hours instead costs
$87,600 and $175,200, respectively.

Provisioned mode requires complete successful resource accounting but can use
unpriced reports. Its hourly rates are explicit planning inputs in the plan's
currency, with a required `rate_source` description. Use an all-in rate for
each node, including platform charges as appropriate. All pools are charged
once per scenario; application costs are **not** added to that bill. Include
retained CPU pools in the candidate even when they run none of the selected
applications. Multiple pools of the same node class are allowed.

For each node class, projected allocation hours must fit the listed annual
capacity. This is only a necessary capacity check: aggregate node-hours do not
prove that peak resource needs, concurrency, data placement or deadlines fit.
The caller must establish those conditions separately.

## Plan example

The values below are synthetic. Replace the application IDs with the IDs in
your two reports; names and ordering are not used to guess a pairing. Each
selected application must appear only once per scenario. `annual_runs` is the
same workload frequency for both scenarios and may be fractional when obtained
by annualizing an observation period.

```json
{
  "schema_version": 1,
  "cost_basis": "allocated",
  "currency": "USD",
  "years": 3,
  "discount_rate_percent": 10,
  "workloads": [
    {
      "name": "daily-etl",
      "annual_runs": 100,
      "baseline_application_id": "application_1_0001",
      "candidate_application_id": "application_2_0001"
    }
  ],
  "baseline": {},
  "candidate": {
    "annual_costs": [],
    "cash_events": [
      {"year": 0, "name": "migration", "amount": 1000}
    ]
  }
}
```

With the $10 and $5 per-run costs above, this yields $500 annual savings,
$500 net savings over three years, 50% ROI, 24 months to sustained payback,
and $243.42599549 NPV at 10%. These are allocated-cost projections; use
provisioned mode to assess the planned whole-fleet cash expense.

For provisioned mode, change `cost_basis` and add `worker_pools` to **both**
scenario objects, using their respective node classes, rates and uptime:

```json
"worker_pools": [
  {
    "node_class": "onprem:worker-8",
    "node_count": 4,
    "uptime_hours_per_year": 8760,
    "hourly_rate": 3.60,
    "rate_source": "Example planning quote, not a measured market price"
  }
]
```

For owned hardware, use a zero rental rate, enter purchase and replacement
payments as `cash_events`, and electricity, maintenance and facility expenses
as named `annual_costs` with an `amount`. Do not put the same purchase in both
an hourly rate and a cash event. These amounts are supplied by the caller;
electricity, depreciation, equipment lifetime and replacement schedules are
not inferred. Known resale receipts can be negative cash events.

## Formulas and timing

```text
AnnualCost = AnnualWorkerCost + sum(AnnualCostItems)
Outflow[0] = CashEvents[0]
Outflow[y] = AnnualCost + CashEvents[y]             for y = 1..years
HorizonCost = sum(Outflow[y])
NetFlow[y] = BaselineOutflow[y] - CandidateOutflow[y]
NetSavings = sum(NetFlow[y])
Investment = sum(max(0, CandidateCashEvents[y] - BaselineCashEvents[y]))
ROI = 100 * NetSavings / Investment               when Investment > 0
NPV = sum(NetFlow[y] / (1 + discount_rate_percent / 100)^y)
```

Year 0 is before the first run. Year 1 is the end of the first operating year,
and so on; a year-`years` event is included at the horizon's end. Payback uses
uniform monthly recurring savings and cash events at those year boundaries.
It reports the first whole month at which cumulative savings become and stay
nonnegative through the horizon, including later replacements. Without an
incremental investment, ROI and payback are `null`. If an investment does not
pay back within the horizon, payback is `null`; a negative ROI is still shown.

The result preserves selected applications and their accounting warnings,
source pricing provenance, the complete plan, annual resource quantities by
node class, and yearly cash flows. Costs are calculated with decimal arithmetic
and emitted as JSON numbers rounded to eight decimal places. Invalid inputs,
missing prices, currency mismatches, failed or incomplete selected runs,
ambiguous IDs and insufficient per-class annual capacity fail the projection.
Unknown plan fields are rejected to catch misspelled cost inputs.

This is a constant-frequency, constant-price scenario calculation for 1 to 50
years. Only explicitly included costs are counted. Successful application
status does not verify equal datasets or correct/equivalent outputs; the caller
must select comparable runs. Failed attempts, startup/shutdown charges,
unlisted workers, control-plane costs, storage, taxes, financing and other
expenses are not inferred. Include known amounts explicitly in the plan.
