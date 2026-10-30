SELECT 
    s.s_name,
    s.s_address,
    SUBSTRING(s.s_comment, 1, 25) AS comment_excerpt,
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_availability,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment,
    CASE 
        WHEN AVG(ps.ps_supplycost) > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS cost_category
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_comment LIKE '%high quality%'
GROUP BY 
    s.s_name, s.s_address, s.s_comment
ORDER BY 
    total_availability DESC
LIMIT 10;
