WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_nationkey, rs.total_supply_cost,
           RANK() OVER (PARTITION BY rs.s_nationkey ORDER BY rs.total_supply_cost DESC) AS supplier_rank
    FROM RankedSuppliers rs
), 
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value, c.c_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
)
SELECT n.n_name, ts.s_name, co.total_order_value
FROM TopSuppliers ts
JOIN nation n ON ts.s_nationkey = n.n_nationkey
JOIN CustomerOrders co ON ts.s_nationkey = co.c_nationkey
WHERE ts.supplier_rank <= 5 
AND co.total_order_value > 10000
ORDER BY n.n_name, ts.total_supply_cost DESC;
