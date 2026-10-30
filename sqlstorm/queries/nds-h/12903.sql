SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    n.n_name, 
    o.o_orderdate 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
GROUP BY 
    p.p_partkey, p.p_name, n.n_name, o.o_orderdate 
ORDER BY 
    revenue DESC 
LIMIT 100;
