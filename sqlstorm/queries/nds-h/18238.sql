SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '1995-01-01' AND l.l_shipdate <= '1996-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
