SELECT 
    p_brand, 
    COUNT(*) AS supplier_count 
FROM 
    partsupp 
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    supplier_count DESC;
