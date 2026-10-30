SELECT 
    p_brand, 
    COUNT(*) AS supplier_count 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p_brand 
ORDER BY 
    supplier_count DESC;
