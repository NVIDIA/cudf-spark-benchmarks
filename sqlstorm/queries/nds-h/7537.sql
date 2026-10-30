WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue
    FROM SupplierRevenue sr
    JOIN supplier s ON sr.s_suppkey = s.s_suppkey
    ORDER BY sr.total_revenue DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT ts.s_name, co.c_name, ts.total_revenue, co.order_count
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.s_suppkey = co.c_custkey
ORDER BY ts.total_revenue DESC, co.order_count DESC;
