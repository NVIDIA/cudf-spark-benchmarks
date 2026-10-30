
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    WHERE s.total_supply_cost > (
        SELECT AVG(rs.total_supply_cost)
        FROM RankedSuppliers rs
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
OrderDetails AS (
    SELECT co.c_custkey, co.o_orderkey, co.o_orderdate, co.o_totalprice, l.l_partkey, l.l_quantity
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > co.o_orderdate
),
SupplierParts AS (
    SELECT ps.ps_partkey, MAX(s.s_name) AS supplier_name
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COUNT(DISTINCT od.o_orderkey) AS num_orders,
    SUM(od.o_totalprice) AS total_spent,
    COUNT(DISTINCT sp.ps_partkey) AS num_parts,
    MAX(sp.supplier_name) AS main_supplier
FROM 
    CustomerOrders co
JOIN 
    OrderDetails od ON co.o_orderkey = od.o_orderkey
JOIN 
    SupplierParts sp ON od.l_partkey = sp.ps_partkey
WHERE 
    co.c_custkey IN (SELECT ts.s_suppkey FROM TopSuppliers ts)
GROUP BY 
    co.c_custkey, co.c_name
HAVING 
    SUM(od.o_totalprice) > 10000
ORDER BY 
    total_spent DESC;
