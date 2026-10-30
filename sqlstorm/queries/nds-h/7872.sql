
WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(l.l_orderkey) AS item_count, SUM(l.l_extendedprice) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sc.total_supplycost
    FROM SupplierCosts sc
    INNER JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    ORDER BY sc.total_supplycost DESC
    LIMIT 5
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.item_count,
    os.total_price,
    ts.s_name AS top_supplier_name,
    ts.total_supplycost
FROM OrderSummary os
JOIN TopSuppliers ts ON ts.total_supplycost = (SELECT MAX(total_supplycost) FROM TopSuppliers)
ORDER BY os.total_price DESC, os.o_orderdate DESC;
