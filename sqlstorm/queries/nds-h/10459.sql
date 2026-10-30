SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ls.l_quantity) AS total_quantity, 
    SUM(ls.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    supplier s ON ls.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
