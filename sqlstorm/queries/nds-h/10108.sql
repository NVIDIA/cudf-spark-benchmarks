SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(lp.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
GROUP BY 
    p.p_partkey, 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
