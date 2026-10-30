
WITH region_summary AS (
    SELECT r.r_regionkey, r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_regionkey, r.r_name
),
order_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
final_summary AS (
    SELECT rs.r_name, os.order_count, os.total_order_value, rs.total_supply_cost
    FROM region_summary rs
    JOIN order_summary os ON rs.r_regionkey = os.c_nationkey
)
SELECT fs.r_name, fs.order_count, fs.total_order_value, fs.total_supply_cost,
       CASE 
           WHEN fs.total_supply_cost > 0 THEN (fs.total_order_value / fs.total_supply_cost)
           ELSE 0 
       END AS cost_to_order_ratio
FROM final_summary fs
ORDER BY cost_to_order_ratio DESC;
