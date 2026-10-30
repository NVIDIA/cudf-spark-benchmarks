SELECT 
    p_brand, 
    COUNT(DISTINCT ps_partkey) AS unique_parts 
FROM 
    part 
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    unique_parts DESC 
LIMIT 10;
