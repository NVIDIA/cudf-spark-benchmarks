SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    l.l_extendedprice
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    l.l_extendedprice DESC
LIMIT 100;