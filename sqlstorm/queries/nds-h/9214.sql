WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
), 
TopCustomers AS (
    SELECT c_name, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RankedOrders
)
SELECT 
    tc.c_name,
    tc.total_revenue,
    r.r_name AS region_name,
    SUM(ps.ps_availqty) AS total_available_quantity
FROM TopCustomers tc
JOIN customer c ON tc.c_name = c.c_name
JOIN supplier s ON c.c_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE tc.revenue_rank <= 10
GROUP BY tc.c_name, tc.total_revenue, r.r_name
ORDER BY total_revenue DESC;
