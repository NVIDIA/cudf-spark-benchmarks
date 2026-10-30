SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    l.l_quantity 
FROM 
    part AS p 
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey 
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31' 
ORDER BY 
    ps.ps_supplycost DESC 
LIMIT 100;