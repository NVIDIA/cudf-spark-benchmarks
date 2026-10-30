SELECT 
    l.l_suppkey, 
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
    partsupp ps ON l.l_partkey = ps.ps_partkey 
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31' 
GROUP BY 
    l.l_suppkey 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
