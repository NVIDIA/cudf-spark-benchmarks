SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    o.o_orderdate,
    c.c_mktsegment,
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
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    l.l_orderkey, o.o_orderdate, c.c_mktsegment, s.s_name, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 100;