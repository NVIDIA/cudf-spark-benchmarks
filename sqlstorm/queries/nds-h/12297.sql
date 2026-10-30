SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_discount) AS average_discount, 
    MAX(l.l_extendedprice) AS max_extended_price 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    s.s_acctbal > 1000 
GROUP BY 
    p.p_name 
ORDER BY 
    total_quantity DESC 
LIMIT 10;
