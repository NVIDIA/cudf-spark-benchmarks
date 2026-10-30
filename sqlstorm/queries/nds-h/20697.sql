WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) as avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) as part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey
    FROM 
        SupplierStats ss
    WHERE 
        ss.avg_supply_cost < (SELECT AVG(ps_supplycost) * 0.9 FROM partsupp)
    UNION ALL
    SELECT 
        s.s_suppkey
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN rp.p_retailprice IS NULL THEN 'Price Not Available'
        WHEN rp.p_retailprice < 10 THEN 'Cheap'
        WHEN rp.p_retailprice BETWEEN 10 AND 100 THEN 'Moderate'
        ELSE 'Expensive'
    END AS price_category,
    RANK() OVER (ORDER BY rp.p_retailprice DESC) AS price_rank
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    highvaluesuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
LEFT JOIN 
    supplier s ON hvs.s_suppkey = s.s_suppkey
WHERE 
    rp.rn = 1
    AND (s.s_comment IS NULL OR s.s_comment NOT LIKE '%dummy%')
ORDER BY 
    rp.p_retailprice DESC;

