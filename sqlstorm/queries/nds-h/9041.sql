WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.total_revenue) AS total_spent
    FROM customer c
    JOIN OrderStats o ON c.c_custkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT rc.s_name, rc.total_cost, tc.total_spent
FROM RankedSuppliers rc
JOIN TopCustomers tc ON rc.total_cost > tc.total_spent
ORDER BY rc.total_cost DESC, tc.total_spent DESC
LIMIT 5;