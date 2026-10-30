SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part AS p
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;