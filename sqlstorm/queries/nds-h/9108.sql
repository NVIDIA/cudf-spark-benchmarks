WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemSummary AS (
    SELECT l.l_orderkey, COUNT(l.l_linenumber) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region_name,
       SUM(CASE WHEN ro.o_totalprice > 1000 THEN ro.o_totalprice ELSE 0 END) AS high_value_order_value,
       COUNT(DISTINCT ro.o_orderkey) AS high_value_order_count,
       SUM(s.total_available_qty) AS total_available_parts,
       AVG(s.avg_supply_cost) AS average_supply_cost,
       SUM(ls.line_count) AS total_lines_in_orders,
       SUM(ls.total_revenue) AS total_revenue_from_orders
FROM RecentOrders ro
JOIN nation n ON ro.o_orderkey % 25 = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SupplierStats s ON ro.o_orderkey % 10 = s.ps_partkey
JOIN LineItemSummary ls ON ro.o_orderkey = ls.l_orderkey
GROUP BY r.r_name
ORDER BY high_value_order_value DESC, total_available_parts DESC;