SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(lp.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
