SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(lp.l_quantity) AS total_quantity, 
    SUM(lp.l_extendedprice) AS total_sales 
FROM 
    part p 
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey 
JOIN 
    supplier s ON lp.l_suppkey = s.s_suppkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey 
GROUP BY 
    p.p_partkey, 
    p.p_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
