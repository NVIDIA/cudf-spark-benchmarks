WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_supplycost, ps.ps_availqty 
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
),
region_performance AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(cd.total_revenue) AS total_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN customer_orders cd ON c.c_custkey = cd.o_custkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, r.customer_count, r.total_revenue, AVG(sd.ps_supplycost) AS avg_supplycost
FROM region_performance r
JOIN supplier_details sd ON sd.s_nationkey = r.r_regionkey
GROUP BY r.r_name, r.customer_count, r.total_revenue
ORDER BY r.total_revenue DESC, r.customer_count DESC
LIMIT 10;