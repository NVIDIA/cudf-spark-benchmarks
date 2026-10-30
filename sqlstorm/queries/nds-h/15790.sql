SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_sales 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
