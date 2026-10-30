SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Product: ', p.p_name, ' | Comment: ', ps.ps_comment) AS detailed_info,
    LENGTH(ps.ps_comment) AS comment_length,
    SUBSTR(ps.ps_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 1000 AND 
    p.p_type LIKE 'METAL%' AND 
    o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, p.p_name, ps.ps_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    comment_length DESC;
