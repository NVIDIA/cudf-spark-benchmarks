SELECT 
    p.p_partkey, 
    p.p_name, 
    sum(l.l_quantity) AS total_quantity, 
    avg(l.l_extendedprice) AS average_price
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 50;
