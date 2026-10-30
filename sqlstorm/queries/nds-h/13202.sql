SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1995-01-01'
GROUP BY 
    p.p_brand, 
    p.p_type, 
    o.o_orderdate
ORDER BY 
    revenue DESC;
