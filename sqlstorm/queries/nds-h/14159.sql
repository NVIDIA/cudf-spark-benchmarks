SELECT 
    n.n_name,
    SUM(line.l_extendedprice * (1 - line.l_discount)) AS revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem line ON o.o_orderkey = line.l_orderkey
JOIN 
    supplier s ON line.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON line.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC;