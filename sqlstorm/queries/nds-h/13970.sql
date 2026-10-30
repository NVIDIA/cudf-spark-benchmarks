SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-01-31'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    revenue DESC;