WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank,
        o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SuppliersAgg AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 5000.00
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment IN ('BUILDING', 'AUTO')
    GROUP BY c.c_custkey
),
MinMaxOrderStats AS (
    SELECT 
        MIN(TotalSpent) AS MinSpent,
        MAX(TotalSpent) AS MaxSpent,
        AVG(OrderCount) AS AvgOrderCount
    FROM CustomerOrders
)
SELECT 
    C.c_custkey,
    C.TotalSpent,
    COALESCE(RO.OrderRank, 0) AS OrderRank,
    B.MinSpent,
    B.MaxSpent,
    B.AvgOrderCount,
    CONCAT('Customer: ', C.c_custkey, ', Total: ', C.TotalSpent) AS CustomerSummary
FROM CustomerOrders C
LEFT JOIN RankedOrders RO ON C.c_custkey = RO.o_orderkey
CROSS JOIN MinMaxOrderStats B
WHERE C.TotalSpent BETWEEN (B.MinSpent * 0.9) AND (B.MaxSpent * 1.1)
AND (C.OrderCount > (SELECT AVG(OrderCount) FROM CustomerOrders) OR C.TotalSpent IS NOT NULL)
ORDER BY C.TotalSpent DESC
LIMIT 5 OFFSET 10;