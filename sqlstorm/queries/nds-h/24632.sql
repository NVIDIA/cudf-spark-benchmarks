
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey
    FROM 
        CustomerOrders c
    WHERE 
        c.OrderCount > (
            SELECT 
                AVG(OrderCount) 
            FROM 
                CustomerOrders
        )
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(r.TotalSupplyCost, 0) AS TotalSupplyCost,
    COALESCE(cs.TotalSpent, 0) AS TotalSpentByHighValueCustomers,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS PriceRank
FROM 
    part p
LEFT JOIN 
    PartSuppliers r ON p.p_partkey = r.ps_partkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey IN (SELECT c.c_custkey FROM HighValueCustomers c)
WHERE 
    p.p_size IN (SELECT p1.p_size FROM part p1 WHERE p1.p_type LIKE '%metal%' GROUP BY p1.p_size ORDER BY MAX(p1.p_retailprice) LIMIT 3)
    AND (p.p_comment IS NULL OR p.p_comment NOT LIKE '%fragile%')
ORDER BY 
    PriceRank, p.p_name DESC
LIMIT 10;
