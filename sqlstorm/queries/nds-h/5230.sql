WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, r.r_name, ns.n_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON s.s_suppkey = rs.s_suppkey
    JOIN nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    ORDER BY rs.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ts.s_name AS supplier_name,
    ts.r_name AS supplier_region,
    co.order_count AS customer_order_count,
    co.total_spent AS customer_total_spent
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.order_count > 5
WHERE ts.total_supply_cost > 10000
ORDER BY ts.total_supply_cost DESC, co.total_spent DESC;
