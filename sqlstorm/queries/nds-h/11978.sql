SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;