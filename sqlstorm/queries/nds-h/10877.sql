SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_availqty,
    SUM(ps.ps_supplycost) AS total_supplycost,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_orders DESC
LIMIT 10;
