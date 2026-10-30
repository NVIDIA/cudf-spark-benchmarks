SELECT 
    p_brand, 
    AVG(ps_supplycost) AS avg_supplycost
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey
GROUP BY 
    p_brand
ORDER BY 
    avg_supplycost DESC;
