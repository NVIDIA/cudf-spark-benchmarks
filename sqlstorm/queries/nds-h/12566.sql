SELECT 
    p.p_name, 
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
    AND o.o_orderdate >= DATE '1994-01-01'
    AND o.o_orderdate < DATE '1995-01-01'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC;
