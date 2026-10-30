
WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
supplier_summary AS (
    SELECT s.s_nationkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_nationkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_revenue AS (
    SELECT n.n_name, SUM(ls.total_revenue) AS nation_revenue
    FROM nation n
    JOIN recent_orders ro ON n.n_nationkey = ro.c_nationkey 
    JOIN lineitem_summary ls ON ro.o_orderkey = ls.l_orderkey
    GROUP BY n.n_name
)

SELECT n.n_name, n.n_comment, COALESCE(sr.supplier_count, 0) AS supplier_count, COALESCE(sr.total_supply_cost, 0) AS total_supply_cost, COALESCE(nr.nation_revenue, 0) AS total_revenue
FROM nation n
LEFT JOIN supplier_summary sr ON n.n_nationkey = sr.s_nationkey
LEFT JOIN nation_revenue nr ON n.n_name = nr.n_name
WHERE COALESCE(sr.supplier_count, 0) > 5
ORDER BY total_revenue DESC;
