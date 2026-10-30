SELECT 
    p.p_brand, 
    SUM(lp.l_quantity) AS total_quantity, 
    SUM(lp.l_extendedprice) AS total_revenue
FROM 
    part p 
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
GROUP BY 
    p.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 10;
