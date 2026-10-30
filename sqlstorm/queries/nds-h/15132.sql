SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
