SELECT 
    n.n_name, 
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue 
FROM 
    customer c 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
GROUP BY 
    n.n_name 
ORDER BY 
    revenue DESC 
LIMIT 10;