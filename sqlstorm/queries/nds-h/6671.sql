
WITH supplier_nation AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
region_summary AS (
    SELECT r.r_regionkey, SUM(ls.total_revenue) AS region_revenue
    FROM lineitem_summary ls
    JOIN customer_orders co ON ls.l_orderkey = co.o_orderkey
    JOIN supplier_nation sn ON co.o_custkey = sn.s_suppkey
    JOIN nation n ON sn.n_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey
)
SELECT r.r_name, rs.region_revenue
FROM region r
JOIN region_summary rs ON r.r_regionkey = rs.r_regionkey
ORDER BY rs.region_revenue DESC
LIMIT 10;
