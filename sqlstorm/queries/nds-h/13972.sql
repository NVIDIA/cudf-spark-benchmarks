SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
ORDER BY 
    total_quantity DESC, avg_price DESC
LIMIT 100;
