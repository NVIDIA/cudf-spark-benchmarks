
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM partsupp ps
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_lines
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.n_nationkey,
    r.n_name,
    COALESCE(SUM(r_cost.ps_supplycost), 0) AS total_supply_cost,
    COALESCE(SUM(line_summary.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT orders.o_orderkey) AS total_orders,
    COUNT(DISTINCT line_summary.l_orderkey) AS total_line_items
FROM nation r
LEFT JOIN supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN SupplierCost r_cost ON s.s_suppkey = r_cost.ps_suppkey AND r_cost.cost_rank = 1
LEFT JOIN RankedOrders orders ON s.s_suppkey = orders.o_orderkey
LEFT JOIN LineItemSummary line_summary ON orders.o_orderkey = line_summary.l_orderkey
WHERE r.n_name LIKE 'A%' OR r.n_name IS NULL
GROUP BY r.n_nationkey, r.n_name
HAVING COUNT(DISTINCT orders.o_orderkey) > 5
ORDER BY total_supply_cost DESC, total_revenue ASC;
