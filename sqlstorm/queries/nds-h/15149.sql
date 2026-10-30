SELECT 
    p.p_name, 
    SUM(ls.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
