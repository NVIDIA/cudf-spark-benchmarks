SELECT 
    p.p_partkey, 
    UPPER(p.p_name) AS upper_part_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS brand_and_type,
    REPLACE(p.p_container, 'Box', 'Container') AS container_type_replaced,
    (SELECT COUNT(*) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    (SELECT AVG(ps.ps_supplycost) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS avg_supply_cost
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
    r.r_name LIKE '%America%' 
    AND p.p_retailprice > 100
ORDER BY 
    upper_part_name DESC;
