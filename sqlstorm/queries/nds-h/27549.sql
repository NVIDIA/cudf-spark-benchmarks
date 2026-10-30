SELECT 
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name) AS info,
    REPLACE(p_comment, 'discount', 'reduced price') AS modified_comment,
    TRIM(LEADING '0' FROM CAST(ps_supplycost AS CHAR(12))) AS cost_no_leading_zero,
    SUBSTR(s_address, 1, 20) AS short_address,
    LENGTH(s_comment) AS comment_length
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    (s_comment LIKE '%important%' OR p_comment LIKE '%important%')
AND 
    s_acctbal BETWEEN 1000.00 AND 5000.00
ORDER BY 
    LENGTH(p_name) DESC, s_name ASC
LIMIT 50;
