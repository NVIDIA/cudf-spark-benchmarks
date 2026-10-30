SELECT 
    p_brand,
    COUNT(*) AS supplier_count,
    AVG(ps_supplycost) AS avg_supplycost
FROM 
    partsupp
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
GROUP BY 
    p_brand
ORDER BY 
    supplier_count DESC;
