WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 30
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sp.ps_partkey,
        sp.ps_availqty,
        sp.ps_supplycost,
        sp.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp sp ON s.s_suppkey = sp.ps_suppkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sp.s_name AS supplier_name,
    sp.ps_availqty,
    sp.ps_supplycost
FROM 
    RankedParts rp
JOIN 
    SupplierParts sp ON rp.p_partkey = sp.ps_partkey
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
