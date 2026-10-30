WITH SupplierStats AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_parts, ss.total_cost
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_parts > 10
    ORDER BY ss.total_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT co.c_custkey, co.c_name, co.order_count, co.total_spent, ts.total_parts, ts.total_cost
FROM CustomerOrders co
JOIN TopSuppliers ts ON co.order_count > 5
WHERE ts.total_cost > 5000
ORDER BY co.total_spent DESC, ts.total_parts DESC;
