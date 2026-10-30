
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
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON c.c_custkey = o.o_custkey 
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01' 
GROUP BY 
    p.p_partkey, 
    p.p_name 
ORDER BY 
    revenue DESC 
LIMIT 10;
