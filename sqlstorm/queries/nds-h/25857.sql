SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(CASE WHEN LENGTH(p.p_comment) > 20 THEN 1 ELSE 0 END) AS long_comment_count,
    AVG(CASE WHEN p.p_size BETWEEN 10 AND 20 THEN p.p_retailprice ELSE NULL END) AS avg_retailprice_size_range
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
    r.r_name LIKE 'EUROPE%'
GROUP BY 
    p.p_brand, 
    p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    supplier_count DESC, 
    avg_retailprice_size_range ASC;
