
SELECT 
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    CASE 
        WHEN LENGTH(p.p_comment) > 10 THEN CONCAT(SUBSTRING(p.p_comment, 1, 10), '...')
        ELSE p.p_comment 
    END AS processed_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 1000.00
AND 
    p.p_type LIKE '%metal%'
GROUP BY 
    supplier_info,
    short_part_name,
    processed_comment
ORDER BY 
    LENGTH(processed_comment) DESC, 
    supplier_info ASC
LIMIT 50;
