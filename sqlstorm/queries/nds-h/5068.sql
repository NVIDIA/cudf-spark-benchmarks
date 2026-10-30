WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.revenue
    FROM RankedOrders r
    WHERE r.rnk <= 10
)
SELECT 
    c.c_name,
    c.c_acctbal,
    SUM(t.revenue) AS total_revenue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN TopOrders t ON o.o_orderkey = t.o_orderkey
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
GROUP BY c.c_name, c.c_acctbal
ORDER BY total_revenue DESC;
