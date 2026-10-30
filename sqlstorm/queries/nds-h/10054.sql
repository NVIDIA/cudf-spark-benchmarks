SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1997-12-31' AND 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    revenue DESC
LIMIT 10;