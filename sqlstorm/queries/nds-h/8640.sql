WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank, c_name
    FROM RankedOrders
)
SELECT tc.rank, tc.c_name, SUM(ro.total_revenue) AS cumulative_revenue
FROM TopCustomers tc
JOIN RankedOrders ro ON tc.c_name = ro.c_name
GROUP BY tc.rank, tc.c_name
ORDER BY cumulative_revenue DESC
LIMIT 10;