SELECT 
    p_name, 
    SUM(l_quantity) AS total_quantity, 
    SUM(l_extendedprice) AS total_revenue 
FROM 
    part 
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey 
GROUP BY 
    p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
