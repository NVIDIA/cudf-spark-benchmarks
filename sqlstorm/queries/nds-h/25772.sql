WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierProductInfo AS (
    SELECT 
        s.s_name AS supplier_name,
        r.r_name AS region,
        pp.p_partkey,
        pp.p_name,
        pp.p_brand,
        pp.p_retailprice
    FROM 
        supplier s
    JOIN region r ON s.s_nationkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedProducts pp ON ps.ps_partkey = pp.p_partkey
)
SELECT 
    AVG(sp.p_retailprice) AS average_price,
    COUNT(DISTINCT sp.supplier_name) AS distinct_suppliers,
    MAX(sp.p_retailprice) AS max_price,
    MIN(sp.p_retailprice) AS min_price
FROM 
    SupplierProductInfo sp
WHERE 
    sp.region = 'Asia'
GROUP BY 
    sp.p_brand
HAVING 
    COUNT(sp.p_partkey) > 5
ORDER BY 
    average_price DESC;
