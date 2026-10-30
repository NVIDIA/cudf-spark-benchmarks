SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    c.c_name,
    s.s_name,
    p.p_name
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1997-12-31' 
GROUP BY 
    l.l_orderkey, o.o_orderdate, c.c_name, s.s_name, p.p_name
ORDER BY 
    revenue DESC;