SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    o.o_orderkey,
    o.o_orderdate
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01'
ORDER BY 
    o.o_orderdate DESC;