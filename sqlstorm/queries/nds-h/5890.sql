WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_name, s.total_supply_value
    FROM RankedSuppliers s
    ORDER BY s.total_supply_value DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, ts.total_supply_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN TopSuppliers ts ON ts.total_supply_value > 50000
    WHERE o.o_orderdate BETWEEN cast('1998-10-01' as date) - INTERVAL '1 year' AND cast('1998-10-01' as date)
)
SELECT co.c_custkey, co.c_name, COUNT(co.o_orderkey) AS order_count, SUM(co.o_totalprice) AS total_spent
FROM CustomerOrders co
GROUP BY co.c_custkey, co.c_name
HAVING COUNT(co.o_orderkey) > 5
ORDER BY total_spent DESC;