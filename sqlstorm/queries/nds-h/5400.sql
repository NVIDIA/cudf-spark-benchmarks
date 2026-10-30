
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.total_cost = (
        SELECT MAX(rs2.total_cost) FROM RankedSuppliers rs2
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    ts.s_name AS top_supplier_name,
    ts.s_suppkey AS top_supplier_key
FROM CustomerOrders co
CROSS JOIN TopSuppliers ts
WHERE co.o_orderdate >= DATE '1996-01-01'
ORDER BY co.o_totalprice DESC, co.o_orderdate ASC
LIMIT 10;
