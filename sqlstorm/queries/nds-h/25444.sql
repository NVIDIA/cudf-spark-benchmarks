
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info,
    LENGTH(s.s_comment) AS comment_length,
    SUBSTRING(s.s_comment, 1, 30) AS short_comment,
    COUNT(DISTINCT ps.ps_partkey) AS supplier_part_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(s.s_name) > 10 
    AND p.p_retailprice > 50.00
    AND s.s_comment LIKE '%important%'
GROUP BY 
    p.p_name, 
    s.s_name, 
    s.s_comment
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 1
ORDER BY 
    total_avail_qty DESC, 
    comment_length ASC
LIMIT 100;
