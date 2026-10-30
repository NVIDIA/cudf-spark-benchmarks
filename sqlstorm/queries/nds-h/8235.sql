WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalSupplyCost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
CustomerRegions AS (
    SELECT DISTINCT c.c_custkey, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT cr.n_regionkey, COUNT(DISTINCT hvo.o_orderkey) AS HighValueOrderCount, 
       SUM(rs.TotalSupplyCost) AS TotalSupplierCost
FROM CustomerRegions cr
LEFT JOIN HighValueOrders hvo ON cr.c_custkey = hvo.o_orderkey
JOIN RankedSuppliers rs ON rs.s_suppkey = cr.c_custkey
GROUP BY cr.n_regionkey
ORDER BY HighValueOrderCount DESC, TotalSupplierCost DESC;
