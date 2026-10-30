SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(ps.ps_supplycost) AS avg_supplycost, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_availqty DESC
LIMIT 100;
