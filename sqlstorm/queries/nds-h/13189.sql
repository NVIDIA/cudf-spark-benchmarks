SELECT 
    p.p_name,
    SUM(ls.l_quantity) AS total_quantity,
    SUM(ls.l_extendedprice) AS total_revenue,
    AVG(ls.l_discount) AS average_discount
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
