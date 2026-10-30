SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(ls.l_orderkey) AS total_orders, 
    SUM(ls.l_extendedprice) AS total_revenue 
FROM 
    part p 
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey 
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey 
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01' 
GROUP BY 
    p.p_partkey, p.p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;