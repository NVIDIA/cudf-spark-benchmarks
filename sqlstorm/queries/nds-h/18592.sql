SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity_sold 
FROM 
    lineitem l 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    total_quantity_sold DESC 
LIMIT 10;
