
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10)
),
RegionalSuppliers AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    COALESCE(rs.total_availqty, 0) AS supplier_availability,
    CASE 
        WHEN rp.brand_count > 5 THEN 'Popular Brand'
        ELSE 'Niche Brand'
    END AS brand_category
FROM 
    RankedParts rp
LEFT JOIN 
    RegionalSuppliers rs ON rp.p_partkey = 
    (SELECT ps.ps_partkey
     FROM partsupp ps
     WHERE ps.ps_suppkey IN (SELECT s.s_suppkey 
                             FROM supplier s 
                             WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2))
     LIMIT 1)
WHERE 
    rp.rn <= 3 AND 
    (rp.p_brand IS NOT NULL OR rp.p_name LIKE '%Gadget%')
ORDER BY 
    rp.p_retailprice DESC 
LIMIT 10;
