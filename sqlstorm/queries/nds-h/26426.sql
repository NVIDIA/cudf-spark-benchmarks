WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey
),
FinalMetrics AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        sc.SupplierCount,
        co.OrderCount,
        co.TotalSpent
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierCount sc ON rp.p_partkey = sc.ps_partkey
    LEFT JOIN 
        CustomerOrders co ON rp.p_partkey = co.c_custkey
    WHERE 
        rp.BrandRank <= 5 AND 
        rp.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
)
SELECT 
    p.p_name,
    p.p_retailprice,
    p.SupplierCount,
    p.OrderCount,
    p.TotalSpent
FROM 
    FinalMetrics p
ORDER BY 
    p.p_retailprice DESC;
