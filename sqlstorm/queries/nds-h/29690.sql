
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUBSTR(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 500.00 
    AND LOWER(s.s_comment) LIKE '%quality%'
GROUP BY 
    p.p_name, s.s_name, p.p_comment 
HAVING 
    SUM(ps.ps_availqty) > 1000 
ORDER BY 
    total_available_quantity DESC, 
    short_comment;
