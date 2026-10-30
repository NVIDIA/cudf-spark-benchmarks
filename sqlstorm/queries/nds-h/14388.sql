SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    s.s_name,
    o.o_orderkey,
    c.c_name,
    l.l_quantity,
    l.l_extendedprice
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 20
    AND s.s_acctbal > 500.00
ORDER BY 
    o.o_orderdate DESC, 
    l.l_extendedprice DESC
LIMIT 100;
