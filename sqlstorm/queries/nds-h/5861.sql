
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.TotalSupplyCost
    FROM supplier s
    JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
    ORDER BY rs.TotalSupplyCost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
LineItemDetails AS (
    SELECT lo.l_orderkey, lo.l_partkey, lo.l_quantity, lo.l_extendedprice, lo.l_discount
    FROM lineitem lo
    WHERE lo.l_shipdate >= '1997-01-01'
)
SELECT 
    co.c_custkey, co.c_name, 
    COUNT(co.o_orderkey) AS TotalOrders,
    SUM(co.o_totalprice) AS TotalSpent,
    AVG(ld.l_extendedprice) AS AvgLineItemPrice,
    ts.s_name AS TopSupplier
FROM CustomerOrders co
LEFT JOIN LineItemDetails ld ON co.o_orderkey = ld.l_orderkey
CROSS JOIN TopSuppliers ts
GROUP BY co.c_custkey, co.c_name, ts.s_name
HAVING COUNT(co.o_orderkey) > 5 AND SUM(co.o_totalprice) > 1000.00
ORDER BY TotalSpent DESC, TotalOrders DESC;
