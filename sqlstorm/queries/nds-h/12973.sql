SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue,
    SUM(l.l_discount) AS total_discount,
    SUM((l.l_extendedprice * (1 - l.l_discount))) AS net_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;