WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(rs.SuppAccountBalance, 0) AS HighestSupplierBalance,
    co.OrderCount,
    co.TotalSpent
FROM 
    part p
LEFT JOIN 
    (SELECT s_suppkey, MAX(s_acctbal) AS SuppAccountBalance
     FROM RankedSuppliers
     WHERE SupplierRank = 1
     GROUP BY s_suppkey) rs ON p.p_partkey = rs.s_suppkey
LEFT JOIN 
    CustomerOrders co ON p.p_partkey = co.c_custkey
WHERE 
    (p.p_size >= 10 AND p.p_retailprice < 50) OR 
    (p.p_size < 10 AND p.p_retailprice >= 50)
ORDER BY 
    HighestSupplierBalance DESC, 
    co.TotalSpent ASC NULLS LAST
LIMIT 100;
