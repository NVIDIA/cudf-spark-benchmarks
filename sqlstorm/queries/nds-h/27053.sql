SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity,
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
    p.p_retailprice > 100.00 
    AND n.n_comment LIKE '%trusted%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, r.r_name
HAVING 
    MIN(ps.ps_supplycost) < 50.00
ORDER BY 
    total_available_quantity DESC
LIMIT 20;
