SELECT 
    p_brand, 
    COUNT(*) AS supplier_count 
FROM 
    supplier 
JOIN 
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey 
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    supplier_count DESC;
