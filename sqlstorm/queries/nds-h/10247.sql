SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    revenue DESC;
