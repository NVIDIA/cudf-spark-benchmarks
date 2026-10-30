SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
