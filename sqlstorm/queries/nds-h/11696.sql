SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    c.c_name, 
    o.o_orderkey, 
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
    s.s_acctbal > 1000
ORDER BY 
    l.l_quantity DESC
LIMIT 100;
