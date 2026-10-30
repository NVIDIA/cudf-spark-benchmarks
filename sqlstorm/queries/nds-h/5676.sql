WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), TopRevenue AS (
    SELECT o.o_orderkey, o.o_orderdate, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RankedOrders o
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, t.total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN TopRevenue t ON o.o_orderkey = t.o_orderkey
    WHERE t.revenue_rank <= 10
)
SELECT co.c_name, SUM(co.total_revenue) AS total_spent
FROM CustomerOrders co
GROUP BY co.c_name
ORDER BY total_spent DESC;