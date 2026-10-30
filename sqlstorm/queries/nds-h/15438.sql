SELECT 
    p_brand, 
    COUNT(*) AS supplier_count
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p_brand
ORDER BY 
    supplier_count DESC;
