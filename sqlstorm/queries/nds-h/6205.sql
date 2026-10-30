WITH supplier_parts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey,
        s.s_name
),
top_suppliers AS (
    SELECT
        sp.s_suppkey,
        sp.s_name,
        sp.part_count,
        sp.total_avail_qty,
        sp.total_supply_cost,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS rank
    FROM
        supplier_parts sp
)
SELECT
    ts.s_name,
    ts.part_count,
    ts.total_avail_qty,
    ts.total_supply_cost,
    ROUND(ts.total_supply_cost / NULLIF(ts.total_avail_qty, 0), 2) AS avg_supply_cost_per_qty
FROM
    top_suppliers ts
WHERE
    ts.rank <= 10
ORDER BY
    ts.total_supply_cost DESC;
