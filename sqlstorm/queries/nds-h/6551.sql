
WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT r.r_regionkey) AS regions_count, SUM(ro.total_spent) AS total_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN RecentOrders ro ON n.n_nationkey = ro.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, ns.regions_count, ns.total_revenue
FROM NationSummary ns
WHERE ns.total_revenue > (SELECT AVG(total_revenue) FROM NationSummary)
ORDER BY ns.total_revenue DESC
LIMIT 10;
