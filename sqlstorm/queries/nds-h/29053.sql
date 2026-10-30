WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
),
RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS supplier_rank
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
    rp.p_retailprice,
    rs.region_name,
    rs.supplier_name,
    rs.s_acctbal
FROM 
    RankedParts rp
JOIN 
    RegionSupplier rs ON rp.p_brand = SUBSTRING(rs.supplier_name, 1, 10)
WHERE 
    rp.price_rank = 1 AND rs.supplier_rank <= 3
ORDER BY 
    rp.p_retailprice DESC, rs.s_acctbal DESC;
