
SELECT 
    p.p_mfgr AS manufacturer, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost,
    REGEXP_REPLACE(p.p_name, '[^[:alnum:][:space:]]', '') AS cleaned_part_name
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
    p.p_type LIKE '%steel%' 
    AND r.r_name IN ('Europe', 'Asia')
GROUP BY 
    p.p_mfgr, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC, manufacturer ASC;
