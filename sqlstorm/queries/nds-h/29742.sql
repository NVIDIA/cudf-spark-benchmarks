
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_name AS part_name,
    rp.p_retailprice AS retail_price,
    si.s_name AS supplier_name,
    si.nation_name,
    si.region_name,
    CONCAT('Part: ', rp.p_name, ', Retail Price: $', CAST(rp.p_retailprice AS DECIMAL(10, 2)), ', Supplier: ', si.s_name) AS part_info
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC;
