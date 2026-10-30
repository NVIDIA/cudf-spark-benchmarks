SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    ps.ps_supplycost,
    sum(l.l_quantity) AS total_quantity,
    sum(l.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost
ORDER BY 
    total_quantity DESC
LIMIT 100;
