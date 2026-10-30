SELECT 
    p.p_brand,
    p.p_type,
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
    customer c ON c.c_custkey = l.l_orderkey
WHERE 
    l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1995-12-31'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    revenue DESC
LIMIT 10;