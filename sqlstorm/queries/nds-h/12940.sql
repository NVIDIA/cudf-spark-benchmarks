SELECT 
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_brand, p.p_type, o.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 100;