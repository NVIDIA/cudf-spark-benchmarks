WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE supplier_rank <= 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS customers_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_item_price
FROM customer cs
JOIN orders o ON cs.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN HighCostSuppliers hcs ON l.l_suppkey = hcs.s_suppkey
JOIN nation n ON cs.c_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY total_order_value DESC;
