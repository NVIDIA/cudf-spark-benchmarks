
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    CONCAT(p.p_name, ' - ', s.s_name, ' (', CAST(SUM(ps.ps_availqty) AS STRING), ' units available)') AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%' AND 
    s.s_comment NOT LIKE '%special order%' 
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_supply_cost DESC, total_available_quantity ASC;
