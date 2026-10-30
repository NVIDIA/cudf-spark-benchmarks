SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand) AS part_info,
    CASE 
        WHEN SUM(ps.ps_supplycost) > 1000 THEN 'High Cost'
        WHEN SUM(ps.ps_supplycost) BETWEEN 500 AND 1000 THEN 'Moderate Cost'
        ELSE 'Low Cost'
    END AS cost_category
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
    p.p_size > 10 AND
    r.r_name LIKE 'Asia%' AND
    s.s_acctbal > 500
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC;
