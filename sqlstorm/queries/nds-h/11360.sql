SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name,
    SUM(ls.l_quantity) AS total_quantity,
    SUM(ls.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
