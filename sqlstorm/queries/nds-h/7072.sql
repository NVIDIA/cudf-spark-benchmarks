WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_supply_cost,
           RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ts.s_name, ts.total_supply_cost, co.c_name, co.order_count, co.total_spent
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.total_spent > ts.total_supply_cost
ORDER BY ts.total_supply_cost DESC, co.total_spent DESC
LIMIT 10;
