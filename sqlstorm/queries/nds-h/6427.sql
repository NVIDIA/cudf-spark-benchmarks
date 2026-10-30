WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
), supplier_info AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), top_suppliers AS (
    SELECT si.*, ROW_NUMBER() OVER (PARTITION BY si.nation_name ORDER BY si.part_count DESC) AS rn
    FROM supplier_info si
)
SELECT ro.o_orderkey, ro.o_orderdate, ro.c_name AS customer_name, ts.s_name AS supplier_name, ts.nation_name, ro.total_revenue
FROM recent_orders ro
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN top_suppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE ts.rn <= 5
ORDER BY ro.o_orderdate DESC, ro.total_revenue DESC
LIMIT 10;