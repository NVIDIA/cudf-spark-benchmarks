
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_brand, 
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name,
        SUBSTRING(s.s_comment, 1, 40) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rp.short_comment AS part_comment,
    si.s_name AS supplier_name, 
    si.region_name,
    si.short_comment AS supplier_comment
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, rp.rank;
