
SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_size) AS min_size,
    CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS description,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_brand LIKE 'Brand%'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, p.p_brand, p.p_type, short_comment, r.r_name, p.p_partkey, r.r_regionkey
ORDER BY 
    avg_supply_cost DESC, supplier_count ASC
LIMIT 50;
