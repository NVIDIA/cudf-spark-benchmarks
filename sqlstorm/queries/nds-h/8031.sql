WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN (SELECT DISTINCT n1.n_name FROM nation n1 WHERE n1.n_regionkey = 
        (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_supply_cost
    FROM RankedSuppliers r
    WHERE r.rank <= 3
)
SELECT
    c.c_name AS customer_name,
    SUM(co.total_order_value) AS total_order_value,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost AS supplier_cost
FROM CustomerOrders co
JOIN TopSuppliers ts ON co.total_order_value > 10000
JOIN customer c ON co.c_custkey = c.c_custkey
GROUP BY c.c_name, ts.s_name, ts.total_supply_cost
ORDER BY total_order_value DESC, ts.total_supply_cost DESC;
