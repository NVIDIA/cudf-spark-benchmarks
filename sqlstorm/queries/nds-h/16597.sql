SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity_sold
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_quantity_sold DESC 
LIMIT 10;
