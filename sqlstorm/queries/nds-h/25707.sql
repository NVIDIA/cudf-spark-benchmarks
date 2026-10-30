
SELECT 
    p.p_name, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    r.r_name AS region_name 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_size > 10 
    AND p.p_retailprice BETWEEN 50.00 AND 150.00 
    AND p.p_comment LIKE '%quality%' 
GROUP BY 
    p.p_name, 
    r.r_name, 
    p.p_comment, 
    LENGTH(p.p_comment) 
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 
ORDER BY 
    comment_length DESC, 
    supplier_count ASC;
