SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(l.l_extendedprice) AS avg_extendedprice
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_availqty DESC, avg_extendedprice DESC
LIMIT 100;
