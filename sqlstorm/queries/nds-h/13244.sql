SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    o.o_orderkey, 
    o.o_totalprice, 
    o.o_orderdate, 
    c.c_name, 
    c.c_acctbal 
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
    o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01' 
ORDER BY 
    o.o_orderdate, 
    p.p_partkey;