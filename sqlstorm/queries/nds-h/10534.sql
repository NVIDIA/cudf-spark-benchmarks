SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    l.l_quantity, 
    l.l_extendedprice, 
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
    o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31' 
ORDER BY 
    o.o_orderdate DESC, 
    l.l_extendedprice DESC 
LIMIT 1000;