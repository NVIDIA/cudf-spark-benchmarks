SELECT 
    p.p_name, 
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS manufacturer_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
    RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS value_rank
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
    r.r_name LIKE '%west%'
    AND p.p_comment NOT LIKE '%no stock%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
HAVING 
    COUNT(ps.ps_suppkey) > 5
ORDER BY 
    value_rank
LIMIT 10;
