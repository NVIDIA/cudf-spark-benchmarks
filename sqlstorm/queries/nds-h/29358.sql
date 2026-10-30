
SELECT 
    LOWER(CONCAT(p.p_name, ' - ', s.s_name)) AS processed_string,
    COUNT(*) AS occurrences
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(*) > 5
ORDER BY 
    occurrences DESC, 
    processed_string ASC;
