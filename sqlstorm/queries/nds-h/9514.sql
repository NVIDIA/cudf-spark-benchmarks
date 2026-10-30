WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue,
        RANK() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM RankedOrders ro
    WHERE ro.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
    AVG(hvo.total_revenue) AS avg_high_value_revenue
FROM HighValueOrders hvo
JOIN customer c ON hvo.o_orderkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY high_value_order_count DESC, avg_high_value_revenue DESC
LIMIT 10;