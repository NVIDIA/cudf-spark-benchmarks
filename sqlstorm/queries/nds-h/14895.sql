SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    l.l_quantity, 
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
ORDER BY 
    o.o_orderdate DESC;