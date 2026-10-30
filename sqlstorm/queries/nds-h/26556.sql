WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%' AND
        p.p_comment NOT LIKE '%defective%'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
)
SELECT 
    r.r_name AS region_name,
    SUM(CASE WHEN rp.rn <= 5 THEN rp.p_retailprice ELSE 0 END) AS top_5_part_value,
    COUNT(DISTINCT rp.p_partkey) AS unique_parts,
    ss.supplier_count,
    ss.total_balance
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierStats ss ON ss.s_nationkey = n.n_nationkey
WHERE 
    rp.p_retailprice > 50
GROUP BY 
    r.r_name, ss.supplier_count, ss.total_balance
ORDER BY 
    top_5_part_value DESC, region_name;
