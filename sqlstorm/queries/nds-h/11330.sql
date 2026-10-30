SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(l.l_extendedprice) AS avg_extendedprice, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01' 
GROUP BY 
    p.p_partkey, p.p_name 
ORDER BY 
    total_availqty DESC 
LIMIT 100;