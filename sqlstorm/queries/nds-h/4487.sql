
WITH SupplierStats AS (
    SELECT ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
HighSpendSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ss.TotalCost,
           ss.PartCount,
           RANK() OVER (ORDER BY ss.TotalCost DESC) AS SpendRank
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
    WHERE ss.TotalCost > (
        SELECT AVG(TotalCost)
        FROM SupplierStats
    )
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS OrderCount,
           SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
RecentOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT hs.s_name AS SupplierName,
       co.c_name AS CustomerName,
       ro.o_orderkey AS OrderKey,
       ro.TotalRevenue,
       ro.o_orderdate,
       hs.PartCount,
       CASE 
           WHEN ro.TotalRevenue IS NULL THEN 'No Revenue'
           ELSE 'Revenue Generated'
       END AS RevenueStatus
FROM HighSpendSuppliers hs
JOIN CustomerOrders co ON hs.s_suppkey = co.c_custkey
FULL OUTER JOIN RecentOrders ro ON co.OrderCount = ro.o_orderkey
WHERE (hs.SpendRank < 5 OR co.TotalSpent > 10000)
ORDER BY hs.TotalCost DESC, co.TotalSpent DESC;
