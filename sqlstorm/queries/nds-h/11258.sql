SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
