SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    UPPER(p_mfgr) AS manufacturer,
    CONCAT('Part: ', p_name, ' | Price: ', p_retailprice) AS detailed_info,
    LENGTH(p_comment) AS comment_length,
    COUNT(DISTINCT s.s_nationkey) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, p.p_comment
HAVING 
    LENGTH(p_comment) > 10 
ORDER BY 
    average_supply_cost DESC 
LIMIT 50;
