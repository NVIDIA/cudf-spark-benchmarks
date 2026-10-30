
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank,
        c.c_custkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, c.c_mktsegment, c.c_custkey
),
TopRevenue AS (
    SELECT 
        r.r_name,
        SUM(ro.revenue) AS total_revenue
    FROM RankedOrders ro
    JOIN nation n ON ro.c_custkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ro.revenue_rank <= 10
    GROUP BY r.r_name
)
SELECT 
    r_name, 
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS region_rank
FROM TopRevenue
ORDER BY region_rank;
