WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           n.n_name AS nation_name,
           COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
LineItemStats AS (
    SELECT l.l_suppkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY l.l_suppkey
),
FinalStats AS (
    SELECT ss.s_suppkey,
           ss.s_name,
           ss.nation_name,
           ss.total_parts,
           ls.total_sales,
           ls.total_orders,
           COALESCE(ls.total_sales / NULLIF(ls.total_orders, 0), 0) AS avg_order_value,
           ss.total_supply_cost
    FROM SupplierStats ss
    LEFT JOIN LineItemStats ls ON ss.s_suppkey = ls.l_suppkey
)
SELECT *,
       CASE 
           WHEN total_orders > 0 THEN total_supply_cost / total_orders 
           ELSE NULL 
       END AS supply_cost_per_order
FROM FinalStats
ORDER BY total_sales DESC, avg_order_value DESC
LIMIT 100;