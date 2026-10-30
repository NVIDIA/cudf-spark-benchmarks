WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY TotalCost DESC) AS RankOrder
    FROM RankedSuppliers s
    WHERE TotalCost > (SELECT AVG(TotalCost) FROM RankedSuppliers)
)
SELECT c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM HighCostSuppliers s WHERE s.RankOrder <= 5)
GROUP BY c.c_name, o.o_orderkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY TotalRevenue DESC;
