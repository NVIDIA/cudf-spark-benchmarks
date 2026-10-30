WITH  nation_summary AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
supplier_summary AS (
    SELECT s.s_nationkey, COUNT(s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS average_balance
    FROM supplier s
    GROUP BY s.s_nationkey
)
SELECT ns.n_name, ns.region_name, ns.total_revenue, ss.supplier_count, ss.average_balance
FROM nation_summary ns
JOIN supplier_summary ss ON ns.n_nationkey = ss.s_nationkey
WHERE ns.total_revenue > 100000
ORDER BY ns.total_revenue DESC, ss.average_balance ASC
LIMIT 10;
