WITH supplier_costs AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
top_suppliers AS (
    SELECT s.s_name, c.c_name, sc.total_cost
    FROM supplier_costs sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
)
SELECT ts.s_name, ts.c_name, ts.total_cost
FROM top_suppliers ts;
