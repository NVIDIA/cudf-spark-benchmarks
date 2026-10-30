WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT s.*, ROW_NUMBER() OVER (ORDER BY TotalSupplyCost DESC) AS SupplierRank
    FROM RankedSuppliers s
    WHERE TotalSupplyCost > (
        SELECT AVG(TotalSupplyCost)
        FROM RankedSuppliers
    )
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1995-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
FinalReport AS (
    SELECT ts.s_suppkey, ts.s_name, od.o_orderkey, od.o_orderdate, od.TotalRevenue
    FROM TopSuppliers ts
    JOIN OrderDetails od ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_brand = 'Brand#1' AND ps.ps_availqty > 10
    )
)
SELECT * 
FROM FinalReport 
ORDER BY TotalRevenue DESC, o_orderdate DESC 
LIMIT 100;
