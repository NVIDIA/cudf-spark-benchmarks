WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalSupplyCost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_custkey, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
OrderDetails AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM lineitem l
    JOIN HighValueOrders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    ts.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS OrderCount, 
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS Revenue
FROM TopSuppliers ts
JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN OrderDetails od ON ps.ps_partkey = od.l_partkey
JOIN HighValueOrders o ON od.o_orderkey = o.o_orderkey
GROUP BY ts.s_name
ORDER BY Revenue DESC;