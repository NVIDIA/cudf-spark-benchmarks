SELECT 
    p.p_name, 
    s.s_name, 
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    revenue DESC
LIMIT 10;