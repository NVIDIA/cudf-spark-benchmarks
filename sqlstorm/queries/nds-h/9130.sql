WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY o.o_orderkey, c.c_mktsegment
)
SELECT 
    c.c_mktsegment,
    COUNT(RankedOrders.o_orderkey) AS num_orders,
    SUM(RankedOrders.total_revenue) AS total_revenue
FROM RankedOrders
JOIN customer c ON RankedOrders.o_orderkey = c.c_custkey
WHERE RankedOrders.rank <= 5
GROUP BY c.c_mktsegment
ORDER BY num_orders DESC, total_revenue DESC;