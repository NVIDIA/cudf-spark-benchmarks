SELECT 
    p_brand, 
    COUNT(DISTINCT ps_suppkey) AS supplier_count, 
    SUM(ps_availqty) AS total_availqty 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    total_availqty DESC 
LIMIT 10;
