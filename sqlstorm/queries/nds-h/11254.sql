SELECT 
    p.p_brand, 
    p.p_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
    COUNT(DISTINCT l.l_orderkey) AS order_count 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey 
WHERE 
    p.p_size = 15 
GROUP BY 
    p.p_brand, p.p_name 
ORDER BY 
    total_cost DESC 
LIMIT 10;
