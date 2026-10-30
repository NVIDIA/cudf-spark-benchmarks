SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    s.s_name, 
    s.s_address, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice 
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
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
ORDER BY 
    o.o_totalprice DESC 
LIMIT 100;