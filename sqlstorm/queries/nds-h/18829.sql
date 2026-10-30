SELECT 
    p_brand, 
    COUNT(*) AS part_count, 
    SUM(ps_supplycost) AS total_supplycost 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    total_supplycost DESC 
LIMIT 10;
