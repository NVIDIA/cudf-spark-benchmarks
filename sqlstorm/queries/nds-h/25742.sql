
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name, ' | ', 
           'Cost: ', CAST(ps.ps_supplycost AS DECIMAL(10, 2)), ' | ', 
           'Comment: ', SUBSTRING(ps.ps_comment, 1, 50)) AS detail
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND p.p_container LIKE '%box%' 
    AND LOWER(s.s_comment) LIKE '%reliable%'
GROUP BY 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    ps.ps_comment
ORDER BY 
    s.s_name ASC, 
    ps.ps_supplycost DESC
LIMIT 20;
