SELECT 
    p_name, 
    SUM(l_quantity) AS total_quantity 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    lineitem ON ps_suppkey = l_suppkey 
GROUP BY 
    p_name 
ORDER BY 
    total_quantity DESC 
LIMIT 10;
