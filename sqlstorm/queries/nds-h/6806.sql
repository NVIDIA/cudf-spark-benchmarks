WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_supply_cost
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
    ORDER BY ss.total_supply_cost DESC
    LIMIT 10
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ts.s_name, co.c_name, co.order_count, co.total_spent
FROM TopSuppliers ts
JOIN CustomerOrderStats co ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
)
ORDER BY co.total_spent DESC, ts.total_supply_cost DESC;
