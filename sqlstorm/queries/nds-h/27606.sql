WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%imported%'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS SupplierInfo
    FROM 
        supplier s
    WHERE 
        s.s_comment LIKE '%reliable%'
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    rp.p_partkey, 
    rp.p_name,
    rp.p_brand,
    sd.SupplierInfo,
    cs.OrderCount,
    cs.TotalSpent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerSummary cs ON cs.OrderCount > 5
WHERE 
    rp.PriceRank <= 3
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
