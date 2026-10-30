SELECT 
    SUBSTR(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS manufacturer_info,
    REPLACE(p.p_comment, 'excellent', 'superb') AS updated_comment,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%brass%'
GROUP BY 
    short_name, manufacturer_info, updated_comment, comment_length
HAVING 
    AVG(ps.ps_supplycost) > 100.00
ORDER BY 
    comment_length DESC, short_name ASC;
