SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1995-01-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    revenue DESC
LIMIT 10;