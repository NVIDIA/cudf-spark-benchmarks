WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as brand_rank
    FROM 
        part p
    WHERE 
        LOWER(p.p_comment) LIKE '%quality%' 
        OR LOWER(p.p_comment) LIKE '%premium%'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    ORDER BY 
        s.s_acctbal DESC
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.short_address,
    si.s_phone,
    si.region_name
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rp.brand_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, si.s_name;
