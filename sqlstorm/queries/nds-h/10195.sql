SELECT 
    l.l_orderkey, 
    l.l_partkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    r.r_name = 'ASIA' 
    AND o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31' 
GROUP BY 
    l.l_orderkey, l.l_partkey 
ORDER BY 
    total_revenue DESC 
LIMIT 10;