WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as CheapestSupplierRank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) as OrderCount,
        SUM(o.o_totalprice) as TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name AS Nation,
    r.r_name AS Region,
    COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
    SUM(COALESCE(coc.OrderCount, 0)) AS TotalOrders,
    SUM(COALESCE(coc.TotalSpent, 0)) AS TotalRevenue,
    AVG(sp.ps_supplycost) AS AvgLowestSupplierCost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN CustomerOrderCounts coc ON c.c_custkey = coc.c_custkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey IN (
        SELECT p_partkey 
        FROM part 
        WHERE p_brand = 'Brand#1' AND p_size > 20
    )
WHERE r.r_name LIKE 'Asia%'
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY TotalRevenue DESC;