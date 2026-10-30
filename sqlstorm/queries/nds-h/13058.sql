
SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    l.l_shipdate >= '1995-01-01' 
    AND l.l_shipdate < '1995-02-01'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 100;
