SELECT 
    p.p_partkey, 
    p.p_name, 
    sum(l.l_quantity) AS total_quantity, 
    sum(l.l_extendedprice) AS total_extended_price 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey 
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01' 
GROUP BY 
    p.p_partkey, p.p_name 
ORDER BY 
    total_quantity DESC 
LIMIT 100;