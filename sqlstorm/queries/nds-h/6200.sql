WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRevenue AS (
    SELECT o.o_orderkey, o.o_orderdate, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS rev_rank
    FROM RankedOrders o
)
SELECT c.c_custkey, c.c_name, c.c_address, c.c_phone, tr.total_revenue
FROM customer c
JOIN TopRevenue tr ON c.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM RankedOrders)
) 
WHERE tr.rev_rank <= 5
ORDER BY tr.total_revenue DESC;