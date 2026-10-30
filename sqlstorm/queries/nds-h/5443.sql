
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_custkey, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ro.total_revenue) AS nation_revenue
    FROM RankedOrders ro
    JOIN customer c ON ro.c_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE ro.revenue_rank <= 10
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region,
    SUM(t.nation_revenue) AS total_nation_revenue
FROM TopNations t
JOIN nation n ON t.n_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_nation_revenue DESC
LIMIT 5;
