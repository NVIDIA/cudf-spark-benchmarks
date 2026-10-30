SELECT 
    p.p_partkey, 
    p.p_name, 
    sum(l.l_quantity) AS total_quantity, 
    sum(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
